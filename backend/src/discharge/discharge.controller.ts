import { Controller, Get } from '@nestjs/common';
import { ok } from '../common/api-response';
import { DischargeService } from './discharge.service';

@Controller('discharge')
export class DischargeController {
  constructor(private readonly dischargeService: DischargeService) {}

  @Get('komering')
  async getKomering() {
    const data = await this.dischargeService.getKomeringDischarge();
    return ok(data);
  }
}
