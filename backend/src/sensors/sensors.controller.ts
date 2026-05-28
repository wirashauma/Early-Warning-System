import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Patch,
  Post,
  Put,
  Query,
  Sse,
  MessageEvent,
} from '@nestjs/common';
import { SensorConnectivity, SensorType } from '@prisma/client';
import { Observable } from 'rxjs';
import { ok } from '../common/api-response';
import { SensorsService } from './sensors.service';
import { RealtimeService } from '../realtime/realtime.service';

interface UpsertSensorRequest {
  sensorId: string;
  name: string;
  type?: SensorType;
  latitude: number;
  longitude: number;
  batteryLevel?: number | null;
  connectivity?: SensorConnectivity;
}

@Controller('sensors')
export class SensorsController {
  constructor(
    private readonly sensorsService: SensorsService,
    private readonly realtimeService: RealtimeService,
  ) {}

  @Sse('stream')
  streamSensors(): Observable<MessageEvent> {
    return this.realtimeService.getSensorStream();
  }

  @Get()
  async findAll(@Query('page') page?: string, @Query('limit') limit?: string) {
    const data = await this.sensorsService.findAll(
      Number(page) || 1,
      Number(limit) || 20,
    );
    return ok(data);
  }

  @Post()
  async create(@Body() body: UpsertSensorRequest) {
    const data = await this.sensorsService.create(body);
    return ok(data);
  }

  @Put(':id')
  async update(
    @Param('id') id: string,
    @Body() body: Partial<UpsertSensorRequest>,
  ) {
    const data = await this.sensorsService.update(id, body);
    return ok(data);
  }

  @Patch(':id')
  async updatePatch(
    @Param('id') id: string,
    @Body() body: Partial<UpsertSensorRequest>,
  ) {
    const data = await this.sensorsService.update(id, body);
    return ok(data);
  }

  @Delete(':id')
  async remove(@Param('id') id: string) {
    const data = await this.sensorsService.remove(id);
    return ok(data);
  }
}
