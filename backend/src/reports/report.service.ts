import { BadRequestException, Injectable } from '@nestjs/common';
import { SensorType } from '@prisma/client';
import ExcelJS from 'exceljs';
import PDFDocument from 'pdfkit';
import { PrismaService } from '../prisma/prisma.service';

type ReportFormat = 'pdf' | 'excel';
type ReportType = 'water_level' | 'rainfall' | 'flow_rate' | 'combined';

interface GenerateReportInput {
  type: string;
  startDate: string;
  endDate: string;
  format: string;
  sensorId?: string;
}

interface GeneratedReport {
  buffer: Buffer;
  filename: string;
  contentType: string;
}

interface BaseReportRow {
  timestamp: Date;
  sensorId: string;
  sensorName: string;
  sensorType: SensorType;
}

interface CombinedReportRow extends BaseReportRow {
  levelCm: number;
  rainfallMm: number;
  flowRateLpm: number;
}

interface SingleReportRow extends BaseReportRow {
  value: number;
  unit: string;
}

interface ReportDataset {
  type: ReportType;
  formatLabel: string;
  title: string;
  subtitle: string;
  start: Date;
  end: Date;
  generatedAt: Date;
  combinedRows?: CombinedReportRow[];
  singleRows?: SingleReportRow[];
  summaryCards: Array<{ label: string; value: string; accent: string }>;
}

@Injectable()
export class ReportService {
  constructor(private readonly prisma: PrismaService) {}

  async generateReport(input: GenerateReportInput): Promise<GeneratedReport> {
    const format = (input.format || '').toLowerCase() as ReportFormat;
    const type = (input.type || '').toLowerCase() as ReportType;

    if (!['pdf', 'excel'].includes(format)) {
      throw new BadRequestException(
        'Format tidak valid. Gunakan format: pdf atau excel.',
      );
    }

    if (!['water_level', 'rainfall', 'flow_rate', 'combined'].includes(type)) {
      throw new BadRequestException(
        'Type tidak valid. Gunakan type: water_level, rainfall, flow_rate, atau combined.',
      );
    }

    if (!input.startDate || !input.endDate) {
      throw new BadRequestException('startDate dan endDate wajib diisi.');
    }

    const start = new Date(input.startDate);
    const end = new Date(input.endDate);

    if (Number.isNaN(start.getTime()) || Number.isNaN(end.getTime())) {
      throw new BadRequestException(
        'Format tanggal tidak valid. Gunakan ISO 8601.',
      );
    }

    if (end < start) {
      throw new BadRequestException('endDate harus lebih besar atau sama dengan startDate.');
    }

    const dataset = await this.loadReportDataset(type, start, end, input.sensorId);
    const timestamp = new Date().toISOString().replace(/[:.]/g, '-');

    if (format === 'pdf') {
      const buffer = await this.buildPdf(dataset);
      return {
        buffer,
        filename: `ews-report-${type}-${timestamp}.pdf`,
        contentType: 'application/pdf',
      };
    }

    const buffer = await this.buildExcel(dataset);
    return {
      buffer,
      filename: `ews-report-${type}-${timestamp}.xlsx`,
      contentType:
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    };
  }

  private async loadReportDataset(
    type: ReportType,
    start: Date,
    end: Date,
    sensorId?: string,
  ): Promise<ReportDataset> {
    const generatedAt = new Date();
    const formatDateRange = `${this.formatDateRange(start)} - ${this.formatDateRange(end)}`;

    const sensorFilter = sensorId && sensorId !== 'all'
      ? { sensorId: sensorId, isActive: true }
      : { isActive: true };

    if (type === 'combined') {
      const [waterLevelLogs, rainfallLogs, flowRateLogs] = await Promise.all([
        this.prisma.waterLevelLog.findMany({
          where: {
            recordedAt: { gte: start, lte: end },
            sensor: { ...sensorFilter, type: SensorType.WATER_LEVEL },
          },
          orderBy: [{ recordedAt: 'asc' }, { sensorId: 'asc' }],
          include: {
            sensor: {
              select: { sensorId: true, name: true, type: true },
            },
          },
        }),
        this.prisma.rainfallLog.findMany({
          where: {
            recordedAt: { gte: start, lte: end },
            sensor: { ...sensorFilter, type: SensorType.RAINFALL },
          },
          orderBy: [{ recordedAt: 'asc' }, { sensorId: 'asc' }],
          include: {
            sensor: {
              select: { sensorId: true, name: true, type: true },
            },
          },
        }),
        this.prisma.flowRateLog.findMany({
          where: {
            recordedAt: { gte: start, lte: end },
            sensor: { ...sensorFilter, type: SensorType.FLOW_RATE },
          },
          orderBy: [{ recordedAt: 'asc' }, { sensorId: 'asc' }],
          include: {
            sensor: {
              select: { sensorId: true, name: true, type: true },
            },
          },
        }),
      ]);

      const combinedRows: CombinedReportRow[] = [
        ...waterLevelLogs.map((item) => ({
          timestamp: item.recordedAt,
          sensorId: item.sensor.sensorId,
          sensorName: item.sensor.name,
          sensorType: item.sensor.type,
          levelCm: this.round(item.waterLevel * 100),
          rainfallMm: 0,
          flowRateLpm: 0,
        })),
        ...rainfallLogs.map((item) => ({
          timestamp: item.recordedAt,
          sensorId: item.sensor.sensorId,
          sensorName: item.sensor.name,
          sensorType: item.sensor.type,
          levelCm: 0,
          rainfallMm: this.round(item.rainfall),
          flowRateLpm: 0,
        })),
        ...flowRateLogs.map((item) => ({
          timestamp: item.recordedAt,
          sensorId: item.sensor.sensorId,
          sensorName: item.sensor.name,
          sensorType: item.sensor.type,
          levelCm: 0,
          rainfallMm: 0,
          flowRateLpm: this.round(item.flowRate),
        })),
      ].sort((a, b) => {
        const ts = a.timestamp.getTime() - b.timestamp.getTime();
        if (ts !== 0) return ts;
        return a.sensorId.localeCompare(b.sensorId);
      });

      const sensorCount = new Set(combinedRows.map((row) => row.sensorId)).size;

      return {
        type,
        formatLabel: 'combined',
        title: 'Laporan (Data Logs & Reporting)',
        subtitle:
          'Analisis historis untuk pelaporan bulanan ke pemerintah daerah dan instansi terkait.',
        start,
        end,
        generatedAt,
        combinedRows,
        summaryCards: [
          {
            label: 'Total Data Terfilter',
            value: combinedRows.length.toString(),
            accent: '#0066FF',
          },
          {
            label: 'Rentang Tanggal',
            value: `${this.formatDateRange(start)}\ns.d. ${this.formatDateRange(end)}`,
            accent: '#0F172A',
          },
          {
            label: 'Filter Sensor',
            value: sensorId && sensorId !== 'all' ? sensorId : 'Semua Sensor Aktif',
            accent: '#0369A1',
          },
        ],
      };
    }

    const sensorType = this.mapReportTypeToSensorType(type);
    const rows = await this.loadSingleTypeRows(type, start, end, sensorType, sensorId);
    const values = rows.map((row) => row.value);
    const sensorCount = new Set(rows.map((row) => row.sensorId)).size;

    return {
      type,
      formatLabel: type,
      title: this.getSingleTypeTitle(type),
      subtitle: this.getSingleTypeSubtitle(type),
      start,
      end,
      generatedAt,
      singleRows: rows,
      summaryCards: [
        {
          label: 'Nilai Minimum',
          value: `${this.formatNumber(values.length ? Math.min(...values) : 0)} ${this.getUnitLabel(type)}`,
          accent: '#1E3A8A',
        },
        {
          label: 'Nilai Rata-rata',
          value: `${this.formatNumber(this.average(values))} ${this.getUnitLabel(type)}`,
          accent: '#1E3A8A',
        },
        {
          label: 'Nilai Terkini',
          value: `${this.formatNumber(values.length ? values[values.length - 1] : 0)} ${this.getUnitLabel(type)}`,
          accent: '#1E3A8A',
        },
      ],
    };
  }

  private async loadSingleTypeRows(
    type: Exclude<ReportType, 'combined'>,
    start: Date,
    end: Date,
    sensorType: SensorType,
    sensorId?: string,
  ): Promise<SingleReportRow[]> {
    const sensorFilter = sensorId && sensorId !== 'all'
      ? { sensorId: sensorId, isActive: true }
      : { isActive: true };

    if (type === 'water_level') {
      const logs = await this.prisma.waterLevelLog.findMany({
        where: {
          recordedAt: { gte: start, lte: end },
          sensor: { ...sensorFilter, type: sensorType },
        },
        orderBy: [{ recordedAt: 'asc' }, { sensorId: 'asc' }],
        include: {
          sensor: { select: { sensorId: true, name: true, type: true } },
        },
      });

      return logs.map((item) => ({
        timestamp: item.recordedAt,
        label: this.formatTimestamp(item.recordedAt),
        sensorId: item.sensor.sensorId,
        sensorName: item.sensor.name,
        sensorType: item.sensor.type,
        value: this.round(item.waterLevel * 100),
        unit: 'cm',
      }));
    }

    if (type === 'rainfall') {
      const logs = await this.prisma.rainfallLog.findMany({
        where: {
          recordedAt: { gte: start, lte: end },
          sensor: { ...sensorFilter, type: sensorType },
        },
        orderBy: [{ recordedAt: 'asc' }, { sensorId: 'asc' }],
        include: {
          sensor: { select: { sensorId: true, name: true, type: true } },
        },
      });

      return logs.map((item) => ({
        timestamp: item.recordedAt,
        label: this.formatTimestamp(item.recordedAt),
        sensorId: item.sensor.sensorId,
        sensorName: item.sensor.name,
        sensorType: item.sensor.type,
        value: this.round(item.rainfall),
        unit: 'mm/jam',
      }));
    }

    const logs = await this.prisma.flowRateLog.findMany({
      where: {
        recordedAt: { gte: start, lte: end },
        sensor: { ...sensorFilter, type: sensorType },
      },
      orderBy: [{ recordedAt: 'asc' }, { sensorId: 'asc' }],
      include: {
        sensor: { select: { sensorId: true, name: true, type: true } },
      },
    });

    return logs.map((item) => ({
      timestamp: item.recordedAt,
      label: this.formatTimestamp(item.recordedAt),
      sensorId: item.sensor.sensorId,
      sensorName: item.sensor.name,
      sensorType: item.sensor.type,
      value: this.round(item.flowRate),
      unit: 'L/min',
    }));
  }

  private async buildPdf(dataset: ReportDataset): Promise<Buffer> {
    return this.renderPdf((doc) => {
      const pageWidth = 595;
      const pageHeight = 842;
      const margin = 40;
      const contentWidth = pageWidth - margin * 2;
      const footerY = pageHeight - 20;

      const drawHeader = () => {
        doc.save();
        doc.rect(0, 0, pageWidth, 60).fill('#1E3A8A');
        doc.restore();

        doc.fillColor('#FFFFFF').font('Helvetica-Bold').fontSize(16).text(dataset.title, margin, 15);
        doc.fillColor('#E2E8F0').font('Helvetica').fontSize(9.5).text('Early Warning System (EWS) • Flood Guard Portal Pemantauan', margin, 32);
        doc.fillColor('#E2E8F0').font('Helvetica').fontSize(8.5).text(`Waktu Cetak: ${this.formatPrintedDate(dataset.generatedAt)} WIB`, margin, 44);

        doc.save();
        doc.rect(0, 60, pageWidth, 3).fill('#3B82F6');
        doc.restore();
      };

      const drawSectionTitle = (title: string, y: number) => {
        doc.fillColor('#0F172A').font('Helvetica-Bold').fontSize(11).text(title, margin, y);
        doc.strokeColor('#3B82F6').lineWidth(1).moveTo(margin, y + 14).lineTo(pageWidth - margin, y + 14).stroke();
        return y + 22;
      };

      const drawSummaryCards = (y: number) => {
        const cardWidth = 163;
        const cardHeight = 40;
        const gap = 13;
        const cardsPerRow = dataset.summaryCards.length;

        dataset.summaryCards.forEach((card, index) => {
          const x = margin + index * (cardWidth + gap);
          doc.save();
          doc.roundedRect(x, y, cardWidth, cardHeight, 4).fillAndStroke('#F8FAFC', '#E2E8F0');
          doc.restore();

          doc.fillColor('#64748B').font('Helvetica').fontSize(8).text(card.label, x + 8, y + 6, {
            width: cardWidth - 16,
            align: 'left',
          });
          doc.fillColor(card.accent).font('Helvetica-Bold').fontSize(13).text(card.value, x + 8, y + 18, {
            width: cardWidth - 16,
            align: 'left',
            height: cardHeight - 24,
          });
        });

        return y + cardHeight + (cardsPerRow > 0 ? 8 : 0);
      };

      const drawFooter = (pageNumber: number, totalPages: number) => {
        doc.save();
        doc.strokeColor('#E2E8F0').lineWidth(0.5).moveTo(margin, footerY - 5).lineTo(pageWidth - margin, footerY - 5).stroke();
        doc.restore();

        doc.fillColor('#94A3B8').font('Helvetica').fontSize(7.5).text(
          `Laporan otomatis digenerate oleh EWS Flood Guard • Halaman ${pageNumber} dari ${totalPages}`,
          pageWidth / 2,
          footerY,
          { align: 'center' },
        );
      };

      const drawTableHeader = (
        columns: string[],
        widths: number[],
        y: number,
      ) => {
        doc.save();
        doc.rect(margin, y, contentWidth, 20).fill('#1E3A8A');
        doc.restore();

        doc.fillColor('#FFFFFF').font('Helvetica-Bold').fontSize(8.5);
        let currentX = margin;
        columns.forEach((column, index) => {
          doc.text(column, currentX + 6, y + 6, { width: widths[index] - 12, align: index === 0 ? 'center' : 'left' });
          currentX += widths[index];
        });

        return y + 20;
      };

      const drawRow = (
        cells: string[],
        widths: number[],
        y: number,
        rowIndex: number,
      ) => {
        const rowHeight = Math.max(
          18,
          ...cells.map((cell, index) =>
            Math.ceil(
              doc.heightOfString(cell, {
                width: widths[index] - 12,
                align: index === 0 ? 'center' : 'left',
              }),
            ) + 10,
          ),
        );

        if (y + rowHeight > pageHeight - 35) {
          doc.addPage();
          drawHeader();
          return { y: 75, needsHeader: true };
        }

        doc.save();
        doc.rect(margin, y, contentWidth, rowHeight).fill(rowIndex % 2 === 0 ? '#F8FAFC' : '#FFFFFF');
        doc.restore();

        doc.strokeColor('#E2E8F0').lineWidth(0.5).moveTo(margin, y + rowHeight).lineTo(pageWidth - margin, y + rowHeight).stroke();

        let currentX = margin;
        doc.fillColor('#0F172A').font('Helvetica').fontSize(8.5);
        cells.forEach((cell, index) => {
          doc.text(cell, currentX + 6, y + (rowHeight - doc.heightOfString(cell, { width: widths[index] - 12 })) / 2, {
            width: widths[index] - 12,
            align: index === 0 ? 'center' : 'left',
          });
          currentX += widths[index];
        });

        return { y: y + rowHeight, needsHeader: false };
      };

      drawHeader();

      let currentY = 75;

      if (dataset.type === 'combined') {
        currentY = drawSectionTitle('I. RINGKASAN DATA LOGS', currentY);
        
        doc.fillColor('#475569').font('Helvetica-Bold').fontSize(8.5);
        doc.text('Parameter:', margin, currentY);
        doc.text('Rentang Waktu:', margin, currentY + 12);
        doc.text('Sensor Aktif:', margin, currentY + 24);

        doc.fillColor('#0F172A').font('Helvetica').fontSize(8.5);
        doc.text('Data teragregasi dari water level, rainfall, dan flow rate', margin + 80, currentY);
        doc.text(`${this.formatDateRange(dataset.start)} - ${this.formatDateRange(dataset.end)}`, margin + 80, currentY + 12);
        doc.text(dataset.summaryCards[2]?.value ?? 'Semua Sensor Aktif', margin + 80, currentY + 24);
        currentY += 40;

        currentY = drawSectionTitle('II. RINGKASAN STATISTIK PENGUKURAN', currentY);
        currentY = drawSummaryCards(currentY);

        currentY = drawSectionTitle('III. TABEL DETAIL HASIL PENGUKURAN', currentY + 4);
        const columns = [
          'No.',
          'Waktu',
          'Sensor',
          'Ketinggian (cm)',
          'Intensitas Hujan (mm/jam)',
          'Debit Air (LPM)',
        ];
        const widths = [30, 90, 80, 95, 130, 90];
        currentY = drawTableHeader(columns, widths, currentY);

        dataset.combinedRows?.forEach((row, index) => {
          const cells = [
            String(index + 1),
            this.formatTableTimestamp(row.timestamp),
            row.sensorId,
            this.formatNumber(row.levelCm),
            this.formatNumber(row.rainfallMm),
            this.formatNumber(row.flowRateLpm),
          ];
          const result = drawRow(cells, widths, currentY, index);
          currentY = result.y;
          if (result.needsHeader) {
            currentY = drawTableHeader(columns, widths, currentY);
          }
        });
      } else {
        const prettyType = this.getPrettyReportName(dataset.type);
        currentY = drawSectionTitle('I. METADATA SENSOR & PARAMETER', currentY);
        
        doc.fillColor('#475569').font('Helvetica-Bold').fontSize(8.5);
        doc.text('Parameter:', margin, currentY);
        doc.text('Tipe Sensor:', margin, currentY + 12);
        doc.text('Rentang Waktu:', margin, currentY + 24);
        doc.text('Status Sistem:', margin, currentY + 36);

        doc.fillColor('#0F172A').font('Helvetica').fontSize(8.5);
        doc.text(prettyType, margin + 80, currentY);
        doc.text(this.getSensorTypeLabel(dataset.type), margin + 80, currentY + 12);
        doc.text(`${this.formatDateRange(dataset.start)} - ${this.formatDateRange(dataset.end)}`, margin + 80, currentY + 24);
        doc.text(`Aktif (${dataset.singleRows?.length ?? 0} data)`, margin + 80, currentY + 36);
        currentY += 52;

        currentY = drawSectionTitle('II. RINGKASAN STATISTIK PENGUKURAN', currentY);
        currentY = drawSummaryCards(currentY);

        currentY = drawSectionTitle('III. TABEL DETAIL HASIL PENGUKURAN', currentY + 4);
        const columns = ['No.', 'Waktu Pengambilan', 'Nilai Parameter', 'Satuan'];
        const widths = [30, 200, 185, 100];
        currentY = drawTableHeader(columns, widths, currentY);

        dataset.singleRows?.forEach((row, index) => {
          const cells = [
            String(index + 1),
            this.formatTableTimestamp(row.timestamp),
            this.formatNumber(row.value),
            row.unit,
          ];
          const result = drawRow(cells, widths, currentY, index);
          currentY = result.y;
          if (result.needsHeader) {
            currentY = drawTableHeader(columns, widths, currentY);
          }
        });
      }

      const totalPages = doc.bufferedPageRange().count;
      for (let page = 0; page < totalPages; page += 1) {
        doc.switchToPage(page);
        drawFooter(page + 1, totalPages);
      }
    });
  }

  private async buildExcel(dataset: ReportDataset): Promise<Buffer> {
    const workbook = new ExcelJS.Workbook();
    workbook.creator = 'EWS Flood Guard';
    workbook.created = new Date();
    workbook.modified = new Date();

    const worksheet = workbook.addWorksheet('Laporan', {
      properties: { defaultRowHeight: 20 },
      views: [{ state: 'frozen', ySplit: 10 }],
      pageSetup: {
        orientation: 'landscape',
        paperSize: 9,
        fitToPage: true,
        fitToWidth: 1,
        fitToHeight: 0,
        margins: {
          left: 0.3,
          right: 0.3,
          top: 0.5,
          bottom: 0.5,
          header: 0.2,
          footer: 0.2,
        },
      },
    });

    const columnCount = dataset.type === 'combined' ? 6 : 4;
    worksheet.columns = Array.from({ length: columnCount }, (_, index) => ({
      width: dataset.type === 'combined'
        ? [6, 22, 22, 18, 22, 18][index]
        : [6, 28, 18, 14][index],
    }));

    const mergeEnd = dataset.type === 'combined' ? 'F' : 'D';
    worksheet.mergeCells(`A1:${mergeEnd}1`);
    const titleCell = worksheet.getCell('A1');
    titleCell.value = dataset.title;
    titleCell.font = { bold: true, color: { argb: 'FFFFFFFF' }, size: 14 };
    titleCell.alignment = { horizontal: 'center', vertical: 'middle' };
    titleCell.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FF1E3A8A' } };
    worksheet.getRow(1).height = 24;

    worksheet.mergeCells(`A2:${mergeEnd}2`);
    const subtitleCell = worksheet.getCell('A2');
    subtitleCell.value = dataset.subtitle;
    subtitleCell.font = { color: { argb: 'FF475569' }, italic: true, size: 10 };
    subtitleCell.alignment = { horizontal: 'left', vertical: 'middle', wrapText: true };
    worksheet.getRow(2).height = 20;

    worksheet.mergeCells(`A3:${mergeEnd}3`);
    const dateCell = worksheet.getCell('A3');
    dateCell.value = `Waktu Cetak: ${this.formatPrintedDate(dataset.generatedAt)} WIB`;
    dateCell.font = { color: { argb: 'FF64748B' }, size: 9 };
    dateCell.alignment = { horizontal: 'left', vertical: 'middle' };

    worksheet.mergeCells(`A5:${mergeEnd}5`);
    const summaryHeader = worksheet.getCell('A5');
    summaryHeader.value = dataset.type === 'combined'
      ? 'RINGKASAN DATA LOGS'
      : 'RINGKASAN STATISTIK PENGUKURAN';
    summaryHeader.font = { bold: true, color: { argb: 'FF0F172A' } };
    summaryHeader.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FFF8FAFC' } };
    summaryHeader.border = this.thinBorder();

    const summaryStartRow = 6;
    if (dataset.type === 'combined') {
      this.writeSummaryRow(worksheet, summaryStartRow, [
        { label: 'Total Data Terfilter', value: dataset.summaryCards[0].value },
        { label: 'Rentang Tanggal', value: dataset.summaryCards[1].value },
        { label: 'Sensor Aktif', value: dataset.summaryCards[2].value },
      ]);
    } else {
      this.writeSummaryRow(worksheet, summaryStartRow, dataset.summaryCards.map((card) => ({
        label: card.label,
        value: card.value,
      })));
    }

    const tableHeaderRow = 10;
    const headers =
      dataset.type === 'combined'
        ? ['No.', 'Waktu', 'Sensor', 'Ketinggian (cm)', 'Intensitas Hujan (mm/jam)', 'Debit Air (LPM)']
        : ['No.', 'Waktu Pengambilan', 'Nilai Parameter', 'Satuan'];

    headers.forEach((header, index) => {
      const cell = worksheet.getCell(tableHeaderRow, index + 1);
      cell.value = header;
      cell.font = { bold: true, color: { argb: 'FFFFFFFF' } };
      cell.alignment = { horizontal: 'center', vertical: 'middle', wrapText: true };
      cell.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FF1E3A8A' } };
      cell.border = this.thinBorder('FFFFFFFF');
    });

    worksheet.getRow(tableHeaderRow).height = 22;

    if (dataset.type === 'combined') {
      dataset.combinedRows?.forEach((row, index) => {
        const rowNumber = tableHeaderRow + 1 + index;
        const values = [
          index + 1,
          this.formatTableTimestamp(row.timestamp),
          row.sensorId,
          this.round(row.levelCm),
          this.round(row.rainfallMm),
          this.round(row.flowRateLpm),
        ];

        values.forEach((value, colIndex) => {
          const cell = worksheet.getCell(rowNumber, colIndex + 1);
          cell.value = value;
          
          const alignment: Partial<ExcelJS.Alignment> = { vertical: 'middle', wrapText: true };
          if (colIndex === 0) {
            alignment.horizontal = 'center';
          } else if (colIndex >= 3) {
            alignment.horizontal = 'right';
            cell.numFmt = '#,##0.00';
          } else {
            alignment.horizontal = 'left';
          }
          cell.alignment = alignment;

          cell.border = this.thinBorder();
          cell.fill = {
            type: 'pattern',
            pattern: 'solid',
            fgColor: { argb: index % 2 === 0 ? 'FFF8FAFC' : 'FFFFFFFF' },
          };
        });
      });
    } else {
      dataset.singleRows?.forEach((row, index) => {
        const rowNumber = tableHeaderRow + 1 + index;
        const values = [
          index + 1,
          this.formatTableTimestamp(row.timestamp),
          this.round(row.value),
          row.unit,
        ];

        values.forEach((value, colIndex) => {
          const cell = worksheet.getCell(rowNumber, colIndex + 1);
          cell.value = value;
          
          const alignment: Partial<ExcelJS.Alignment> = { vertical: 'middle', wrapText: true };
          if (colIndex === 0) {
            alignment.horizontal = 'center';
          } else if (colIndex === 2) {
            alignment.horizontal = 'right';
            cell.numFmt = '#,##0.00';
          } else {
            alignment.horizontal = 'left';
          }
          cell.alignment = alignment;

          cell.border = this.thinBorder();
          cell.fill = {
            type: 'pattern',
            pattern: 'solid',
            fgColor: { argb: index % 2 === 0 ? 'FFF8FAFC' : 'FFFFFFFF' },
          };
        });
      });
    }

    const tableEndRow = tableHeaderRow + (dataset.type === 'combined' ? dataset.combinedRows?.length ?? 0 : dataset.singleRows?.length ?? 0) + 1;
    worksheet.autoFilter = {
      from: { row: tableHeaderRow, column: 1 },
      to: { row: tableEndRow, column: headers.length },
    };

    return Buffer.from(await workbook.xlsx.writeBuffer());
  }

  private async renderPdf(
    draw: (doc: InstanceType<typeof PDFDocument>) => void,
  ): Promise<Buffer> {
    return new Promise((resolve, reject) => {
      const doc = new PDFDocument({
        size: 'A4',
        margin: 0,
        bufferPages: true,
      });

      const chunks: Buffer[] = [];
      doc.on('data', (chunk: Buffer | Uint8Array) => {
        chunks.push(Buffer.from(chunk));
      });
      doc.on('error', reject);
      doc.on('end', () => resolve(Buffer.concat(chunks)));

      draw(doc);
      doc.end();
    });
  }

  private writeSummaryRow(
    worksheet: ExcelJS.Worksheet,
    row: number,
    cards: Array<{ label: string; value: string }>,
  ) {
    const cellsPerCard = 2;
    cards.forEach((card, index) => {
      const startColumn = index * cellsPerCard + 1;
      const endColumn = startColumn + cellsPerCard - 1;
      worksheet.mergeCells(row, startColumn, row, endColumn);
      worksheet.mergeCells(row + 1, startColumn, row + 1, endColumn);

      const labelCell = worksheet.getCell(row, startColumn);
      labelCell.value = card.label;
      labelCell.font = { color: { argb: 'FF64748B' }, size: 9 };
      labelCell.alignment = { horizontal: 'left', vertical: 'middle' };
      labelCell.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FFF8FAFC' } };
      labelCell.border = this.thinBorder();

      const valueCell = worksheet.getCell(row + 1, startColumn);
      valueCell.value = card.value;
      valueCell.font = { bold: true, color: { argb: 'FF1E3A8A' }, size: 11 };
      valueCell.alignment = { horizontal: 'left', vertical: 'middle', wrapText: true };
      valueCell.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FFF8FAFC' } };
      valueCell.border = this.thinBorder();
    });
  }

  private thinBorder(color = 'FFE2E8F0'): Partial<ExcelJS.Borders> {
    return {
      top: { style: 'thin', color: { argb: color } },
      left: { style: 'thin', color: { argb: color } },
      bottom: { style: 'thin', color: { argb: color } },
      right: { style: 'thin', color: { argb: color } },
    };
  }

  async deleteFiltered(input: {
    startDate?: string;
    endDate?: string;
    sensorId?: string;
  }) {
    const { startDate, endDate, sensorId } = input;

    // Build the date range condition
    const dateCondition: any = {};
    if (startDate) {
      dateCondition.gte = new Date(startDate);
    }
    if (endDate) {
      dateCondition.lte = new Date(endDate);
    }

    const whereClause: any = {};
    if (Object.keys(dateCondition).length > 0) {
      whereClause.recordedAt = dateCondition;
    }

    let deletedWaterLevels = 0;
    let deletedRainfalls = 0;
    let deletedFlowRates = 0;

    if (!sensorId || sensorId === 'all') {
      // If sensorId is "all" or not provided, delete from all active sensors' logs
      const [wlResult, rfResult, frResult] = await Promise.all([
        this.prisma.waterLevelLog.deleteMany({
          where: {
            ...whereClause,
            sensor: { isActive: true },
          },
        }),
        this.prisma.rainfallLog.deleteMany({
          where: {
            ...whereClause,
            sensor: { isActive: true },
          },
        }),
        this.prisma.flowRateLog.deleteMany({
          where: {
            ...whereClause,
            sensor: { isActive: true },
          },
        }),
      ]);
      deletedWaterLevels = wlResult.count;
      deletedRainfalls = rfResult.count;
      deletedFlowRates = frResult.count;
    } else {
      // Find the sensor first to check its type and get its internal UUID id
      const sensor = await this.prisma.sensor.findFirst({
        where: { sensorId, isActive: true },
      });

      if (!sensor) {
        throw new BadRequestException('Sensor tidak ditemukan atau tidak aktif.');
      }

      // Delete only from the specific sensor's log table
      if (sensor.type === SensorType.WATER_LEVEL) {
        const result = await this.prisma.waterLevelLog.deleteMany({
          where: {
            ...whereClause,
            sensorId: sensor.id,
          },
        });
        deletedWaterLevels = result.count;
      } else if (sensor.type === SensorType.RAINFALL) {
        const result = await this.prisma.rainfallLog.deleteMany({
          where: {
            ...whereClause,
            sensorId: sensor.id,
          },
        });
        deletedRainfalls = result.count;
      } else if (sensor.type === SensorType.FLOW_RATE) {
        const result = await this.prisma.flowRateLog.deleteMany({
          where: {
            ...whereClause,
            sensorId: sensor.id,
          },
        });
        deletedFlowRates = result.count;
      }
    }

    return {
      message: 'Data terfilter berhasil dihapus.',
      deletedCounts: {
        waterLevels: deletedWaterLevels,
        rainfalls: deletedRainfalls,
        flowRates: deletedFlowRates,
        total: deletedWaterLevels + deletedRainfalls + deletedFlowRates,
      },
    };
  }

  private mapReportTypeToSensorType(type: Exclude<ReportType, 'combined'>): SensorType {
    if (type === 'water_level') {
      return SensorType.WATER_LEVEL;
    }

    if (type === 'rainfall') {
      return SensorType.RAINFALL;
    }

    return SensorType.FLOW_RATE;
  }

  private getSingleTypeTitle(type: Exclude<ReportType, 'combined'>): string {
    switch (type) {
      case 'water_level':
        return 'LAPORAN RESMI PEMANTAUAN KETINGGIAN AIR';
      case 'rainfall':
        return 'LAPORAN RESMI PEMANTAUAN CURAH HUJAN';
      default:
        return 'LAPORAN RESMI PEMANTAUAN DEBIT AIR';
    }
  }

  private getSingleTypeSubtitle(type: Exclude<ReportType, 'combined'>): string {
    switch (type) {
      case 'water_level':
        return 'Early Warning System (EWS) • Flood Guard Portal Pemantauan';
      case 'rainfall':
        return 'Early Warning System (EWS) • Flood Guard Portal Pemantauan';
      default:
        return 'Early Warning System (EWS) • Flood Guard Portal Pemantauan';
    }
  }

  private getPrettyReportName(type: ReportType): string {
    switch (type) {
      case 'water_level':
        return 'Ketinggian Air Terintegrasi (Water Level)';
      case 'rainfall':
        return 'Curah Hujan Bulanan (Rainfall Intensity)';
      case 'flow_rate':
        return 'Debit Air Terintegrasi (Water Flow Speed)';
      default:
        return 'Data Logs & Reporting';
    }
  }

  private getSensorTypeLabel(type: ReportType): string {
    switch (type) {
      case 'water_level':
        return 'Telemetri Radar / Ultrasonik IoT';
      case 'rainfall':
        return 'Telemetri Stasiun Cuaca Kenten (Live)';
      case 'flow_rate':
        return 'Telemetri Flow Rate / IoT Sensor';
      default:
        return 'Teragregasi Multi Sensor';
    }
  }

  private getUnitLabel(type: Exclude<ReportType, 'combined'>): string {
    switch (type) {
      case 'water_level':
        return 'cm';
      case 'rainfall':
        return 'mm';
      default:
        return 'L/min';
    }
  }

  private average(values: number[]): number {
    if (values.length === 0) {
      return 0;
    }

    return values.reduce((sum, value) => sum + value, 0) / values.length;
  }

  private round(value: number): number {
    return Number(value.toFixed(2));
  }

  private formatNumber(value: number): string {
    return Number(value).toFixed(2).replace(/\.00$/, '');
  }

  private formatPrintedDate(date: Date): string {
    return new Intl.DateTimeFormat('id-ID', {
      weekday: 'long',
      year: 'numeric',
      month: 'long',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
      hour12: false,
    }).format(date);
  }

  private formatDateRange(date: Date): string {
    return new Intl.DateTimeFormat('id-ID', {
      day: '2-digit',
      month: 'short',
      year: 'numeric',
    }).format(date);
  }

  private formatTimestamp(date: Date): string {
    return new Intl.DateTimeFormat('id-ID', {
      day: '2-digit',
      month: '2-digit',
      year: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
      hour12: false,
    }).format(date);
  }

  private formatTableTimestamp(date: Date): string {
    return new Intl.DateTimeFormat('id-ID', {
      year: 'numeric',
      month: '2-digit',
      day: '2-digit',
      hour: '2-digit',
      minute: '2-digit',
      hour12: false,
    }).format(date);
  }
}
