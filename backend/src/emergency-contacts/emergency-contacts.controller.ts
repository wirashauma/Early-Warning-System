import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Patch,
  Post,
} from '@nestjs/common';
import { EmergencyCategory } from '@prisma/client';
import { Public } from '../auth/public.decorator';
import { ok } from '../common/api-response';
import {
  EmergencyContactsService,
  UpsertContactDto,
} from './emergency-contacts.service';

@Controller('emergency-contacts')
export class EmergencyContactsController {
  constructor(
    private readonly emergencyContactsService: EmergencyContactsService,
  ) {}

  // ── Public: anyone can read active contacts ────────────────────────────
  @Public()
  @Get()
  async findAll() {
    const data = await this.emergencyContactsService.findAll();
    return ok(data);
  }

  // ── Protected: admin management endpoints ─────────────────────────────
  @Get('admin/all')
  async findAllAdmin() {
    const data = await this.emergencyContactsService.findAllAdmin();
    return ok(data);
  }

  @Post()
  async create(@Body() body: UpsertContactDto) {
    const data = await this.emergencyContactsService.create(body);
    return ok(data);
  }

  @Patch(':id')
  async update(
    @Param('id') id: string,
    @Body() body: Partial<UpsertContactDto>,
  ) {
    const data = await this.emergencyContactsService.update(id, body);
    return ok(data);
  }

  @Delete(':id')
  async remove(@Param('id') id: string) {
    const data = await this.emergencyContactsService.remove(id);
    return ok(data);
  }
}
