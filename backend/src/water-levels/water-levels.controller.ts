import { Controller, Get, Param, Query } from '@nestjs/common';
import { ok } from '../common/api-response';
import { WaterLevelsService } from './water-levels.service';
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
@Controller('water-levels')
export class WaterLevelsController {
  constructor(private readonly waterLevelsService: WaterLevelsService) {}

  @Get('current')
  async getCurrent() {
    const data = await this.waterLevelsService.getCurrent();
    return ok(data);
  }

  @Get('history')
  async getHistory(@Query() query: HistoryQuery) {
    const data = await this.waterLevelsService.getHistory(query);
    return ok(data);
  }

  @Get(':sensorId/latest')
  async getLatestBySensor(@Param('sensorId') sensorId: string) {
    const data = await this.waterLevelsService.getLatestBySensor(sensorId);
    return ok(data);
  }
}
