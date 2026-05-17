import { Controller, Get, Query } from '@nestjs/common';
import { ok } from '../common/api-response';
import { FlowRateService } from './flow-rate.service';

interface HistoryQuery {
  sensorId?: string;
  startDate?: string;
  endDate?: string;
  interval?: 'hourly' | 'daily' | 'weekly';
  page?: string;
  limit?: string;
}

@Controller('flow-rate')
export class FlowRateController {
  constructor(private readonly flowRateService: FlowRateService) {}

  @Get('current')
  async getCurrent() {
    const data = await this.flowRateService.getCurrent();
    return ok(data);
  }

  @Get('history')
  async getHistory(@Query() query: HistoryQuery) {
    const data = await this.flowRateService.getHistory(query);
    return ok(data);
  }
}
