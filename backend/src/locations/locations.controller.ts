import { Controller, Get } from '@nestjs/common';
import { ok } from '../common/api-response';
import { LocationsService } from './locations.service';
import { Public } from '../auth/public.decorator';

@Controller('locations')
export class LocationsController {
  constructor(private readonly locationsService: LocationsService) {}

  @Public()
  @Get('sensors')
  async getSensorLocations() {
    const data = await this.locationsService.getSensorLocations();
    return ok(data);
  }
}
