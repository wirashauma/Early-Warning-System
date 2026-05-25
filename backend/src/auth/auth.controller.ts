import {
  Body,
  Controller,
  Get,
  HttpCode,
  Post,
  Put,
  Request,
  UseGuards,
} from '@nestjs/common';
import { ok } from '../common/api-response';
import { AuthService } from './auth.service';
import { JwtAuthGuard } from './jwt-auth.guard';

interface LoginRequest {
  email: string;
  password: string;
}

interface RegisterRequest {
  name: string;
  email: string;
  password: string;
  institution?: string;
}

interface RefreshRequest {
  refreshToken: string;
}

interface GoogleLoginRequest {
  idToken: string;
}

interface AuthenticatedRequest {
  user: {
    email: string;
    id: string;
    role: string;
  };
}

@Controller('auth')
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  @Post('register')
  @HttpCode(201)
  async register(@Body() body: RegisterRequest) {
    const data = await this.authService.register(body);
    return ok(data);
  }

  @Post('login')
  @HttpCode(200)
  async login(@Body() body: LoginRequest) {
    const data = await this.authService.login(body);
    return ok(data);
  }

  @Post('refresh')
  @HttpCode(200)
  async refresh(@Body() body: RefreshRequest) {
    const data = await this.authService.refresh(body.refreshToken);
    return ok(data);
  }

  @Post('google-login')
  @HttpCode(200)
  async googleLogin(@Body() body: GoogleLoginRequest) {
    const data = await this.authService.googleLogin(body.idToken);
    return ok(data);
  }

  @UseGuards(JwtAuthGuard)
  @Get('me')
  @HttpCode(200)
  async me(@Request() req: AuthenticatedRequest) {
    const data = await this.authService.getProfile(req.user.id);
    return ok(data);
  }

  // --- ENDPOINT UPDATE PROFILE BARU ---
  @UseGuards(JwtAuthGuard)
  @Put('profile')
  @HttpCode(200)
  async updateProfile(
    @Request() req: AuthenticatedRequest,
    @Body()
    body: {
      name?: string;
      avatar?: string;
      phone?: string;
      institution?: string;
      notificationFlood?: boolean;
      notificationStatus?: boolean;
      notificationEmail?: boolean;
    },
  ) {
    const data = await this.authService.updateProfile(req.user.id, body);
    return ok(data);
  }

  @UseGuards(JwtAuthGuard)
  @Put('notifications/read-all')
  @HttpCode(200)
  async markNotificationsReadAll(@Request() req: AuthenticatedRequest) {
    const data = await this.authService.markAllNotificationsRead(req.user.id);
    return ok(data);
  }

  @UseGuards(JwtAuthGuard)
  @Post('logout')
  @HttpCode(200)
  logout(@Request() req: AuthenticatedRequest) {
    return ok({ message: `Logout berhasil untuk user: ${req.user.email}` });
  }
}
