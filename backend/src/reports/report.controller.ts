import { Controller, Get, Query, Res, StreamableFile, UseGuards, Delete } from '@nestjs/common';
import type { Response } from 'express';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { ReportService } from './report.service';
import { ok } from '../common/api-response';

@Controller('reports')
export class ReportController {
  constructor(private readonly reportService: ReportService) {}

  @UseGuards(JwtAuthGuard)
  @Get('generate')
  async generate(
    @Query('type') type: string,
    @Query('startDate') startDate: string,
    @Query('endDate') endDate: string,
    @Query('format') format: string,
    @Query('sensorId') sensorId: string,
    @Res({ passthrough: true }) res: Response,
  ): Promise<StreamableFile> {
    const report = await this.reportService.generateReport({
      type,
      startDate,
      endDate,
      format,
      sensorId,
    });

    res.setHeader('Content-Type', report.contentType);
    res.setHeader('Content-Disposition', `attachment; filename="${report.filename}"`);
    res.setHeader('Content-Length', report.buffer.length.toString());
    res.setHeader('Cache-Control', 'no-store');

    return new StreamableFile(report.buffer);
  }

  @UseGuards(JwtAuthGuard)
  @Delete('delete-filtered')
  async deleteFiltered(
    @Query('startDate') startDate?: string,
    @Query('endDate') endDate?: string,
    @Query('sensorId') sensorId?: string,
  ) {
    const result = await this.reportService.deleteFiltered({
      startDate,
      endDate,
      sensorId,
    });
    return ok(result);
  }
}
