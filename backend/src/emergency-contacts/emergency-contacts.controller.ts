import { Controller, Get } from '@nestjs/common';
import { ok } from '../common/api-response';
import { EmergencyContactsService } from './emergency-contacts.service';
import { Public } from '../auth/public.decorator';

@Controller('emergency-contacts')
export class EmergencyContactsController {
  constructor(
    private readonly emergencyContactsService: EmergencyContactsService,
  ) {}

  @Public()
  @Get()
  async findAll() {
    const data = await this.emergencyContactsService.findAll();
    return ok(data);
  }
}
