"use client";

import { useEffect, useState, useMemo, useRef } from "react";
import {
  BarChart,
  Bar,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
} from "recharts";
import type { WaterLevelPoint } from "@/types/water-level";
import jsPDF from "jspdf";
import html2canvas from "html2canvas-pro";

interface FlowSpeedChartProps {
  points: WaterLevelPoint[];
}

export function FlowSpeedChart({ points = [] }: FlowSpeedChartProps) {
  const [mounted, setMounted] = useState(false);
  const [range, setRange] = useState<"day" | "week">("day");
  const cardRef = useRef<HTMLDivElement>(null);

  const handleExportPDF = async () => {
    if (!cardRef.current) return;
    try {
      const exportBtn = cardRef.current.querySelector(".pdf-export-btn") as HTMLElement;
      if (exportBtn) exportBtn.style.opacity = "0";

      // Capture chart visual cleanly
      const chartEl = cardRef.current.querySelector(".chart-container-capture") as HTMLElement;
      let chartImg = "";
      if (chartEl) {
        const canvas = await html2canvas(chartEl, {
          scale: 2,
          useCORS: true,
          backgroundColor: "#ffffff",
        });
        chartImg = canvas.toDataURL("image/png");
      }

      if (exportBtn) exportBtn.style.opacity = "1";

      // Initialize jsPDF A4 portrait
      const pdf = new jsPDF({
        orientation: "portrait",
        unit: "mm",
        format: "a4",
      });

      // Page dimensions
      const pageWidth = 210;
      const pageHeight = 297;
      const margin = 15;
      const contentWidth = pageWidth - 2 * margin;

      // 1. TOP HEADER BANNER (Navy Theme)
      pdf.setFillColor(30, 58, 138); // Navy blue
      pdf.rect(0, 0, pageWidth, 38, "F");

      pdf.setTextColor(255, 255, 255);
      pdf.setFont("helvetica", "bold");
      pdf.setFontSize(14);
      pdf.text("LAPORAN RESMI PEMANTAUAN DEBIT AIR", margin, 13);

      pdf.setFont("helvetica", "normal");
      pdf.setFontSize(9);
      pdf.setTextColor(226, 232, 240);
      pdf.text("Early Warning System (EWS) • Flood Guard Portal Pemantauan", margin, 19);

      // Current formatted date
      const now = new Date();
      const formattedDate = now.toLocaleDateString("id-ID", {
        weekday: "long",
        year: "numeric",
        month: "long",
        day: "numeric",
        hour: "2-digit",
        minute: "2-digit",
      });
      pdf.setFontSize(8);
      pdf.text(`Waktu Cetak: ${formattedDate} WIB`, margin, 31);

      // Decorative accent line
      pdf.setFillColor(59, 130, 246); // Accent blue
      pdf.rect(0, 38, pageWidth, 2, "F");

      // 2. METADATA SECTION
      let currentY = 49;
      pdf.setTextColor(15, 23, 42); // slate-900
      pdf.setFont("helvetica", "bold");
      pdf.setFontSize(10);
      pdf.text("I. METADATA SENSOR & PARAMETER", margin, currentY);

      // Separator Line
      pdf.setDrawColor(226, 232, 240);
      pdf.setLineWidth(0.3);
      pdf.line(margin, currentY + 2, pageWidth - margin, currentY + 2);

      // Metadata values
      currentY += 8;
      pdf.setFont("helvetica", "bold");
      pdf.setFontSize(8);
      pdf.setTextColor(71, 85, 105); // slate-600
      pdf.text("Parameter:", margin, currentY);
      pdf.text("Tipe Sensor:", margin + 85, currentY);
      
      pdf.setFont("helvetica", "normal");
      pdf.setTextColor(15, 23, 42);
      pdf.text("Debit Air Terintegrasi (Water Flow Speed)", margin + 22, currentY);
      pdf.text("Telemetri Flow Rate / IoT Sensor", margin + 110, currentY);

      currentY += 5;
      pdf.setFont("helvetica", "bold");
      pdf.setTextColor(71, 85, 105);
      pdf.text("Rentang Waktu:", margin, currentY);
      pdf.text("Status Sistem:", margin + 85, currentY);

      pdf.setFont("helvetica", "normal");
      pdf.setTextColor(15, 23, 42);
      pdf.text(range === "day" ? "Harian (24 Jam Terakhir)" : "Mingguan (7 Hari Terakhir)", margin + 22, currentY);
      pdf.text(`${trendLabel} (${latest} L/m)`, margin + 110, currentY);

      // 3. STATISTIK SUMMARY CARD BOXES
      currentY += 12;
      pdf.setFont("helvetica", "bold");
      pdf.setFontSize(10);
      pdf.setTextColor(15, 23, 42);
      pdf.text("II. RINGKASAN STATISTIK PENGUKURAN", margin, currentY);
      pdf.line(margin, currentY + 2, pageWidth - margin, currentY + 2);

      currentY += 6;
      const cardWidth = 56;
      const cardHeight = 15;
      const cardGap = 6;

      // Card 1: Minimum
      pdf.setFillColor(248, 250, 252);
      pdf.setDrawColor(226, 232, 240);
      pdf.roundedRect(margin, currentY, cardWidth, cardHeight, 1.5, 1.5, "FD");
      pdf.setFont("helvetica", "normal");
      pdf.setFontSize(7.5);
      pdf.setTextColor(100, 116, 139);
      pdf.text("Nilai Minimum", margin + 4, currentY + 5);
      pdf.setFont("helvetica", "bold");
      pdf.setFontSize(10.5);
      pdf.setTextColor(30, 58, 138);
      pdf.text(`${min} L/m`, margin + 4, currentY + 11);

      // Card 2: Rata-rata
      pdf.setFillColor(248, 250, 252);
      pdf.roundedRect(margin + cardWidth + cardGap, currentY, cardWidth, cardHeight, 1.5, 1.5, "FD");
      pdf.setFont("helvetica", "normal");
      pdf.setFontSize(7.5);
      pdf.setTextColor(100, 116, 139);
      pdf.text("Nilai Rata-rata", margin + cardWidth + cardGap + 4, currentY + 5);
      pdf.setFont("helvetica", "bold");
      pdf.setFontSize(10.5);
      pdf.setTextColor(30, 58, 138);
      pdf.text(`${average} L/m`, margin + cardWidth + cardGap + 4, currentY + 11);

      // Card 3: Terkini
      pdf.setFillColor(248, 250, 252);
      pdf.roundedRect(margin + (cardWidth + cardGap) * 2, currentY, cardWidth, cardHeight, 1.5, 1.5, "FD");
      pdf.setFont("helvetica", "normal");
      pdf.setFontSize(7.5);
      pdf.setTextColor(100, 116, 139);
      pdf.text("Nilai Saat Ini", margin + (cardWidth + cardGap) * 2 + 4, currentY + 5);
      pdf.setFont("helvetica", "bold");
      pdf.setFontSize(10.5);
      pdf.setTextColor(30, 58, 138);
      pdf.text(`${latest} L/m`, margin + (cardWidth + cardGap) * 2 + 4, currentY + 11);

      // 4. CHART IMAGE
      currentY += cardHeight + 8;
      pdf.setFont("helvetica", "bold");
      pdf.setFontSize(10);
      pdf.setTextColor(15, 23, 42);
      pdf.text("III. VISUALISASI TREN GRAFIK", margin, currentY);
      pdf.line(margin, currentY + 2, pageWidth - margin, currentY + 2);

      currentY += 6;
      if (chartImg) {
        // Place chart visual beautifully (centered, clean aspect ratio)
        pdf.addImage(chartImg, "PNG", margin, currentY, contentWidth, 54);
        currentY += 58;
      } else {
        currentY += 4;
      }

      // 5. DETAILED DATA TABLE
      currentY += 4;
      pdf.setFont("helvetica", "bold");
      pdf.setFontSize(10);
      pdf.setTextColor(15, 23, 42);
      pdf.text("IV. TABEL DETAIL HASIL PENGUKURAN", margin, currentY);
      pdf.line(margin, currentY + 2, pageWidth - margin, currentY + 2);

      currentY += 6;
      
      // Draw Table Header
      const colWidths = [20, 85, 45, 30]; // Sums up to 180
      const colNames = ["No.", range === "day" ? "Index Ingest / Hari Pengukuran" : "Hari Pengukuran", "Nilai Parameter", "Satuan"];
      
      pdf.setFillColor(30, 58, 138);
      pdf.rect(margin, currentY, contentWidth, 7, "F");
      
      pdf.setTextColor(255, 255, 255);
      pdf.setFont("helvetica", "bold");
      pdf.setFontSize(8);
      
      let colX = margin;
      for (let i = 0; i < colNames.length; i++) {
        pdf.text(colNames[i], colX + 4, currentY + 5);
        colX += colWidths[i];
      }
      
      currentY += 7;
      
      // Draw Table Rows
      pdf.setFont("helvetica", "normal");
      pdf.setFontSize(8);
      
      chartData.forEach((row, idx) => {
        // Handle page overflow dynamically!
        if (currentY > pageHeight - 20) {
          // Draw page footer before adding new page
          pdf.setFont("helvetica", "normal");
          pdf.setFontSize(7);
          pdf.setTextColor(148, 163, 184);
          pdf.text("EWS Flood Guard • Halaman 1", pageWidth / 2, pageHeight - 10, { align: "center" });

          pdf.addPage();
          currentY = 20; // reset Y on page 2

          // Draw a quick sub-header on page 2
          pdf.setFillColor(30, 58, 138);
          pdf.rect(margin, currentY, contentWidth, 7, "F");
          pdf.setTextColor(255, 255, 255);
          pdf.setFont("helvetica", "bold");
          let subColX = margin;
          for (let i = 0; i < colNames.length; i++) {
            pdf.text(colNames[i], subColX + 4, currentY + 5);
            subColX += colWidths[i];
          }
          currentY += 7;
          pdf.setFont("helvetica", "normal");
          pdf.setFontSize(8);
        }

        // Alternating row background
        if (idx % 2 === 0) {
          pdf.setFillColor(248, 250, 252); // slate-50
        } else {
          pdf.setFillColor(255, 255, 255);
        }
        pdf.rect(margin, currentY, contentWidth, 5.5, "F");
        
        // Draw row borders
        pdf.setDrawColor(241, 245, 249);
        pdf.line(margin, currentY + 5.5, pageWidth - margin, currentY + 5.5);
        
        pdf.setTextColor(15, 23, 42);
        
        // Row contents
        pdf.text((idx + 1).toString(), margin + 4, currentY + 4);
        pdf.text(row.label, margin + colWidths[0] + 4, currentY + 4);
        pdf.text(row.value.toString(), margin + colWidths[0] + colWidths[1] + 4, currentY + 4);
        pdf.text("L/min", margin + colWidths[0] + colWidths[1] + colWidths[2] + 4, currentY + 4);
        
        currentY += 5.5;
      });

      // 6. BOTTOM FOOTER SIGNATURE & BRANDING
      const totalPages = pdf.getNumberOfPages();
      for (let p = 1; p <= totalPages; p++) {
        pdf.setPage(p);
        pdf.setFont("helvetica", "normal");
        pdf.setFontSize(7);
        pdf.setTextColor(148, 163, 184);
        pdf.text(
          `Laporan otomatis digenerate oleh EWS Flood Guard • Halaman ${p} dari ${totalPages}`,
          pageWidth / 2,
          pageHeight - 10,
          { align: "center" }
        );
      }

      pdf.save(`Laporan_Debit_Air_${range.toUpperCase()}_${now.toISOString().slice(0,10)}.pdf`);
    } catch (err) {
      console.error("PDF Export failed:", err);
    }
  };

  useEffect(() => {
    setMounted(true);
  }, []);

  const isDemo = points.length === 0;

  const validPoints = useMemo(() => {
    if (isDemo) return [];
    return points.filter((point) => point && point.flowRateLpm !== null && point.flowRateLpm !== undefined && point.flowRateLpm !== 0);
  }, [points, isDemo]);

  const referenceNow = useMemo(() => {
    const activePoints = isDemo ? points : validPoints;
    if (activePoints.length === 0) return 0;
    return new Date(activePoints[activePoints.length - 1].timestamp).getTime();
  }, [points, validPoints, isDemo]);

  const isMultiDay = useMemo(() => {
    const activePoints = isDemo ? points : validPoints;
    if (activePoints.length < 2) return false;
    const firstTime = new Date(activePoints[0].timestamp).getTime();
    const lastTime = new Date(activePoints[activePoints.length - 1].timestamp).getTime();
    const diffHours = (lastTime - firstTime) / (1000 * 60 * 60);
    return diffHours > 24;
  }, [points, validPoints, isDemo]);

  const formatXAxisTick = (value: any) => {
    if (!value) return "";
    try {
      const date = new Date(value);
      if (Number.isNaN(date.getTime())) return String(value);

      if (isMultiDay) {
        const months = ["Jan", "Feb", "Mar", "Apr", "Mei", "Jun", "Jul", "Agu", "Sep", "Okt", "Nov", "Des"];
        const day = date.getDate();
        const month = months[date.getMonth()];
        const hours = String(date.getHours()).padStart(2, "0");
        const minutes = String(date.getMinutes()).padStart(2, "0");
        return `${day} ${month} ${hours}:${minutes}`;
      } else {
        const hours = String(date.getHours()).padStart(2, "0");
        const minutes = String(date.getMinutes()).padStart(2, "0");
        return `${hours}:${minutes}`;
      }
    } catch (e) {
      return String(value);
    }
  };

  // Aggregate and filter data points for Recharts based on range selection
  const chartData = useMemo(() => {
    if (isDemo) {
      const baseTime = Date.now();
      const basePoints = [13.0, 16.8, 15.2, 15.8, 14.0, 14.0, 11.5, 15.0, 15.0, 15.0, 13.0, 14.0, 18.0, 18.0, 15.0, 12.2, 10.6, 12.0, 26.6, 20.3];
      return basePoints.map((val, index) => {
        const offsetMinutes = (basePoints.length - 1 - index) * 10;
        const timestamp = baseTime - offsetMinutes * 60 * 1000;
        return {
          label: (index + 1).toString(),
          value: val,
          timestamp,
        };
      });
    }

    const activePoints = validPoints;
    if (activePoints.length === 0) return [];

    const dayAgo = referenceNow - 24 * 60 * 60 * 1000;
    const weekAgo = referenceNow - 7 * 24 * 60 * 60 * 1000;

    if (range === "day") {
      const daily = activePoints.filter((point) => new Date(point.timestamp).getTime() >= dayAgo);
      const source = daily.length > 0 ? daily : activePoints;

      return source.map((point, index) => {
        const val = point.flowRateLpm ?? Number((point.levelCm / 260 + point.rainfallMm / 40).toFixed(2));
        return {
          label: (index + 1).toString(),
          value: parseFloat(val.toFixed(2)),
          timestamp: new Date(point.timestamp).getTime(),
        };
      });
    }

    const weekly = activePoints.filter((point) => new Date(point.timestamp).getTime() >= weekAgo);
    const source = weekly.length > 0 ? weekly : activePoints;

    const grouped = new Map<string, { sum: number; count: number; ts: number }>();
    source.forEach((point) => {
      const date = new Date(point.timestamp);
      const key = date.toISOString().slice(0, 10);
      const val = point.flowRateLpm ?? Number((point.levelCm / 260 + point.rainfallMm / 40).toFixed(2));
      const current = grouped.get(key) ?? { sum: 0, count: 0, ts: date.getTime() };
      grouped.set(key, {
        sum: current.sum + val,
        count: current.count + 1,
        ts: Math.max(current.ts, date.getTime()),
      });
    });

    return Array.from(grouped.entries())
      .sort((a, b) => a[1].ts - b[1].ts)
      .slice(-7)
      .map(([key, value], index) => ({
        label: (index + 1).toString(),
        value: parseFloat((value.sum / Math.max(value.count, 1)).toFixed(2)),
        timestamp: value.ts,
      }));
  }, [validPoints, range, referenceNow, isDemo]);

  // Hardcoded ticks removed in favor of responsive, auto-calculated date/time ticks.

  // Calculations for stats boxes at the bottom
  const values = chartData.map((p) => p.value);
  const min = isDemo ? 10.6 : (values.length > 0 ? Math.min(...values) : 0);
  const max = isDemo ? 26.6 : (values.length > 0 ? Math.max(...values) : 0);
  const latest =
    isDemo ? 20.3 : (validPoints.length > 0
      ? parseFloat((validPoints[validPoints.length - 1].flowRateLpm ?? Number((validPoints[validPoints.length - 1].levelCm / 260 + validPoints[validPoints.length - 1].rainfallMm / 40).toFixed(2))).toFixed(2))
      : 0);
  const average =
    isDemo ? 15.5 : (values.length > 0
      ? parseFloat((values.reduce((sum, v) => sum + v, 0) / values.length).toFixed(2))
      : 0);

  // Status Badge and Trend Resolution
  const trendClass =
    latest >= 20
      ? "bg-rose-50 text-rose-700 border-rose-100"
      : latest >= 10
      ? "bg-amber-50 text-amber-700 border-amber-100"
      : "bg-emerald-50 text-emerald-700 border-emerald-100";
  const trendLabel = latest >= 20 ? "Debit Tinggi" : latest >= 10 ? "Debit Sedang" : "Debit Rendah";

  if (!mounted) {
    return <div className="h-[430px] w-full animate-pulse rounded-xl bg-slate-50" />;
  }

  const isEmpty = false;

  return (
    <div ref={cardRef} className="flex flex-col h-full justify-between">
      {/* Unified Header - 2 Rows Compact Layout to prevent wrapping */}
      <div className="w-full mb-4">
        <div className="flex flex-row justify-between items-center w-full mb-2">
          <h3 className="text-base font-bold text-slate-800 leading-tight">Grafik Debit Air</h3>
          <button
            type="button"
            onClick={handleExportPDF}
            className="pdf-export-btn inline-flex items-center gap-1 rounded-md border border-rose-200 bg-rose-50/80 px-2 py-0.5 text-[11px] font-bold text-rose-700 transition hover:bg-rose-100 cursor-pointer shadow-3xs"
          >
            <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor" className="h-3 w-3">
              <path fillRule="evenodd" d="M4.5 2A1.5 1.5 0 003 3.5v13A1.5 1.5 0 004.5 18h11a1.5 1.5 0 001.5-1.5V7.621a1.5 1.5 0 00-.44-1.06l-4.12-4.122A1.5 1.5 0 0011.378 2H4.5zm2.25 8.5a.75.75 0 000 1.5h6.5a.75.75 0 000-1.5h-6.5zm0 3a.75.75 0 000 1.5h6.5a.75.75 0 000-1.5h-6.5z" clipRule="evenodd" />
            </svg>
            PDF
          </button>
        </div>
        <div className="flex flex-row items-center justify-between w-full pb-2 border-b border-slate-100">
          <div className="inline-flex rounded-full bg-slate-100 p-0.5 border border-slate-200 text-xs">
            <button
              type="button"
              onClick={() => setRange("day")}
              className={`rounded-full px-3 py-0.5 font-medium transition-colors ${
                range === "day"
                  ? "bg-white text-blue-600 shadow-xs font-semibold"
                  : "text-slate-500 hover:text-slate-800"
              }`}
            >
              Day
            </button>
            <button
              type="button"
              onClick={() => setRange("week")}
              className={`rounded-full px-3 py-0.5 font-medium transition-colors ${
                range === "week"
                  ? "bg-white text-blue-600 shadow-xs font-semibold"
                  : "text-slate-500 hover:text-slate-800"
              }`}
            >
              Week
            </button>
          </div>
          <span className={`rounded-full px-2 py-0.5 text-xs font-semibold border whitespace-nowrap ${trendClass}`}>
            {trendLabel} ({latest} L/m)
          </span>
        </div>
      </div>

      {/* Chart Wrapper Area */}
      <div className="relative flex-grow flex flex-col justify-center min-h-[250px] w-full mb-4">
        <div className="chart-container-capture h-[250px] w-full">
          <ResponsiveContainer width="100%" height="100%">
            <BarChart data={chartData} margin={{ top: 15, right: 5, left: -20, bottom: 0 }}>
              <CartesianGrid strokeDasharray="3 3" stroke="#f1f5f9" vertical={false} />
              
              <XAxis
                dataKey="timestamp"
                axisLine={{ stroke: "#e2e8f0" }}
                tickLine={false}
                tick={{ fill: "#64748b", fontSize: 10, fontWeight: 500 }}
                tickFormatter={(value) => {
                  if (isDemo) {
                    if (!value) return "";
                    try {
                      const date = new Date(value);
                      if (range === "day") {
                        const h = String(date.getHours()).padStart(2, "0");
                        const m = String(date.getMinutes()).padStart(2, "0");
                        return `${h}:${m}`;
                      }
                      return date.toLocaleDateString("id-ID", {
                        weekday: "short",
                      });
                    } catch (e) {
                      return String(value);
                    }
                  }
                  return formatXAxisTick(value);
                }}
              />
              <YAxis
                domain={[0, 30]}
                ticks={[0, 5, 10, 15, 20, 25, 30]}
                axisLine={{ stroke: "#e2e8f0" }}
                tickLine={false}
                tick={{ fill: "#64748b", fontSize: 10 }}
              />
              <Tooltip
                cursor={{ fill: "#f8fafc", opacity: 0.8 }}
                content={({ active, payload }) => {
                  if (active && payload && payload.length) {
                    const datum = payload[0].payload;
                    const timeStr = datum.timestamp
                      ? new Date(datum.timestamp).toLocaleTimeString("id-ID", {
                          hour: "2-digit",
                          minute: "2-digit",
                        })
                      : `Titik ${datum.label}`;
                    const tooltipLabel = range === "day"
                      ? `Waktu Ingest: ${timeStr}`
                      : `Hari: ${datum.timestamp ? new Date(datum.timestamp).toLocaleDateString("id-ID", { weekday: "long" }) : `Titik ${datum.label}`}`;
                    return (
                      <div className="rounded-lg border border-slate-200 bg-white/95 p-2.5 shadow-md backdrop-blur-xs">
                        <p className="text-[10px] font-bold text-slate-400 uppercase tracking-wider">
                          {tooltipLabel}
                        </p>
                        <p className="mt-0.5 text-sm font-black text-blue-600">
                          {payload[0].value} <span className="text-xs font-semibold text-slate-500">L/min</span>
                        </p>
                      </div>
                    );
                  }
                  return null;
                }}
              />
              <Bar
                dataKey="value"
                fill="#3b82f6"
                radius={[4, 4, 0, 0]}
                maxBarSize={16}
              />
            </BarChart>
          </ResponsiveContainer>
        </div>
      </div>

       {/* Standardized Statistics Grid Footer */}
      <div className="grid grid-cols-3 gap-2 mt-2">
        <div className="rounded-lg bg-slate-50 p-2.5 text-center border border-slate-100/40">
          <p className="text-[10px] sm:text-xs text-slate-500 font-medium whitespace-nowrap">Minimum</p>
          <p className="text-xs sm:text-sm font-bold text-slate-700 mt-0.5 whitespace-nowrap">{min} L/m</p>
        </div>
        <div className="rounded-lg bg-slate-50 p-2.5 text-center border border-slate-100/40">
          <p className="text-[10px] sm:text-xs text-slate-500 font-medium whitespace-nowrap">Rata-rata</p>
          <p className="text-xs sm:text-sm font-bold text-slate-700 mt-0.5 whitespace-nowrap">{average} L/m</p>
        </div>
        <div className="rounded-lg bg-slate-50 p-2.5 text-center border border-slate-100/40">
          <p className="text-[10px] sm:text-xs text-slate-500 font-medium whitespace-nowrap">Saat Ini</p>
          <p className="text-xs sm:text-sm font-bold text-slate-700 mt-0.5 whitespace-nowrap">{latest} L/m</p>
        </div>
      </div>
    </div>
  );
}
