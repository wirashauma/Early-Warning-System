import {
  Body,
  Controller,
  Get,
  HttpCode,
  Param,
  Post,
  Put,
  Request,
  UseGuards,
  UseInterceptors,
  UploadedFile,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { ok } from '../common/api-response';
import { AuthService } from './auth.service';
import { JwtAuthGuard } from './jwt-auth.guard';
import { Public } from './public.decorator';
import { StorageService } from '../common/storage/storage.service';

interface LoginRequest {
  email: string;
  password: string;
}

interface RegisterRequest {
  name: string;
  email: string;
  password: string;
  institution?: string;
  phone?: string;
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
  constructor(
    private readonly authService: AuthService,
    private readonly storageService: StorageService,
  ) {}

  @Public()
  @Post('register')
  @HttpCode(201)
  async register(@Body() body: RegisterRequest) {
    const data = await this.authService.register(body);
    return ok(data);
  }

  @Public()
  @Post('login')
  @HttpCode(200)
  async login(@Body() body: LoginRequest) {
    const data = await this.authService.login(body);
    return ok(data);
  }

  @Public()
  @Post('refresh')
  @HttpCode(200)
  async refresh(@Body() body: RefreshRequest) {
    const data = await this.authService.refresh(body.refreshToken);
    return ok(data);
  }

  @Public()
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
  @UseInterceptors(FileInterceptor('avatar'))
  @HttpCode(200)
  async updateProfile(
    @Request() req: AuthenticatedRequest,
    @UploadedFile() file: Express.Multer.File,
    @Body()
    body: {
      name?: string;
      phone?: string;
      institution?: string;
      notificationFlood?: string;
      notificationStatus?: string;
      notificationEmail?: string;
      removeAvatar?: string;
    },
  ) {
    const parsedData: any = {
      name: body.name,
      phone: body.phone,
      institution: body.institution,
    };

    if (body.notificationFlood !== undefined) {
      parsedData.notificationFlood = body.notificationFlood === 'true';
    }
    if (body.notificationStatus !== undefined) {
      parsedData.notificationStatus = body.notificationStatus === 'true';
    }
    if (body.notificationEmail !== undefined) {
      parsedData.notificationEmail = body.notificationEmail === 'true';
    }

    if (body.removeAvatar === 'true' || body.removeAvatar === '') {
      parsedData.avatar = null;
    } else if (file) {
      const avatarUrl = await this.storageService.uploadAvatar(
        file.buffer,
        file.originalname,
        file.mimetype,
      );
      parsedData.avatar = avatarUrl;
    }

    const data = await this.authService.updateProfile(req.user.id, parsedData);
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
  @Put('notifications/:id/read')
  @HttpCode(200)
  async markNotificationRead(@Request() req: AuthenticatedRequest, @Param('id') id: string) {
    const data = await this.authService.markNotificationRead(req.user.id, id);
    return ok(data);
  }

  @UseGuards(JwtAuthGuard)
  @Post('logout')
  @HttpCode(200)
  logout(@Request() req: AuthenticatedRequest) {
    return ok({ message: `Logout berhasil untuk user: ${req.user.email}` });
  }
}
