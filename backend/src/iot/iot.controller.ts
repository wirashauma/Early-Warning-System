import { Body, Controller, Post } from '@nestjs/common';
import { ok, type ApiResponse } from '../common/api-response';
import { IngestPayload } from './dto/ingest.dto';
import { IotService, type IngestResult } from './iot.service';

@Controller('iot')
export class IotController {
  constructor(private readonly iotService: IotService) {}

  @Post('ingest')
  async ingest(@Body() body: IngestPayload): Promise<ApiResponse<IngestResult>> {
    const data = await this.iotService.ingest(body);
    return ok(data, 'Ingest accepted');
  }
}
