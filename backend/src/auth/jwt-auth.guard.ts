import {
  CanActivate,
  ExecutionContext,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import * as jwt from 'jsonwebtoken';
import { JWT_SECRET } from './auth.constants';
import { PrismaService } from '../prisma/prisma.service';
import { IS_PUBLIC_KEY } from './public.decorator';

interface AuthUser {
  id: string;
  email: string;
  role: string;
}

@Injectable()
export class JwtAuthGuard implements CanActivate {
  constructor(
    private readonly prisma: PrismaService,
    private readonly reflector: Reflector,
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const isPublic = this.reflector.getAllAndOverride<boolean>(IS_PUBLIC_KEY, [
      context.getHandler(),
      context.getClass(),
    ]);

    if (isPublic) {
      return true;
    }

    const request = context.switchToHttp().getRequest<{
      headers: { authorization?: string };
      user?: AuthUser;
    }>();

    const authHeader = request.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      throw new UnauthorizedException('Silakan login terlebih dahulu.');
    }

    const token = authHeader.slice(7);

    let payload: { sub: string; email: string; role: string };

    try {
      const decoded = jwt.verify(token, JWT_SECRET) as {
        sub: string;
        email: string;
        role: string;
      };
      payload = decoded;
    } catch {
      throw new UnauthorizedException('Silakan login terlebih dahulu.');
    }

    const user = await this.prisma.user.findUnique({
      where: { id: payload.sub },
    });

    if (!user || !user.isActive) {
      throw new UnauthorizedException('Akses ditolak atau user tidak aktif.');
    }

    request.user = {
      id: user.id,
      email: user.email,
      role: user.role,
    };

    return true;
  }
}

