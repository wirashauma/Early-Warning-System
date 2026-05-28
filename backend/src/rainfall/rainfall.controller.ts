import { Controller, Get, Query } from '@nestjs/common';
import { ok } from '../common/api-response';
import { RainfallService } from './rainfall.service';
import { Public } from '../auth/public.decorator';

interface HistoryQuery {
  sensorId?: string;
  startDate?: string;
  endDate?: string;
  interval?: 'hourly' | 'daily' | 'weekly';
  page?: string;
  limit?: string;
}

@Public()
@Controller('rainfall')
export class RainfallController {
  constructor(private readonly rainfallService: RainfallService) {}

  @Get('current')
  async getCurrent() {
    const data = await this.rainfallService.getCurrent();
    return ok(data);
  }

  @Get('history')
  async getHistory(@Query() query: HistoryQuery) {
    const data = await this.rainfallService.getHistory(query);
    return ok(data);
  }

  @Get('kenten')
  async getKenten() {
    const data = await this.rainfallService.getKentenRainfall();
    return ok(data);
  }
}
