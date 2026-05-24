import {
  Injectable,
  UnauthorizedException,
  BadRequestException,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { UserRole } from '@prisma/client';
import * as bcrypt from 'bcrypt';
import * as admin from 'firebase-admin';
import { JWT_SECRET } from './auth.constants';
import { PrismaService } from '../prisma/prisma.service';

interface LoginPayload {
  email: string;
  password: string;
}

interface RegisterPayload {
  email: string;
  password: string;
  name: string;
  institution?: string;
}

interface UpdateProfilePayload {
  name?: string;
  avatar?: string | null;
  phone?: string | null;
  institution?: string | null;
}

interface JwtPayload {
  sub: string;
  email: string;
  role: UserRole;
}

interface FirebaseDecodedToken {
  uid: string;
  email?: string;
  name?: string;
  picture?: string;
}

interface UserWithTokenFields {
  id: string;
  email: string;
  role: UserRole;
}

interface PublicUserFields extends UserWithTokenFields {
  name: string;
  avatar?: string | null;
  institution?: string | null;
  phone?: string | null;
}

@Injectable()
export class AuthService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly jwtService: JwtService,
  ) {}

  // --- FUNGSI REGISTER BARU ---
  async register(payload: RegisterPayload) {
    const email = payload.email.trim().toLowerCase();
    const name = payload.name.trim();
    const institution = payload.institution?.trim() || null;

    if (!name) {
      throw new BadRequestException('Nama wajib diisi.');
    }

    const existingUser = await this.prisma.user.findUnique({
      where: { email },
    });
    if (existingUser) {
      throw new BadRequestException('Email sudah terdaftar. Silakan login.');
    }

    const hashedPassword = await bcrypt.hash(payload.password, 10);

    const newUser = await this.prisma.user.create({
      data: {
        email,
        name,
        password: hashedPassword,
        institution,
        role: UserRole.USER,
        isActive: true,
      },
    });

    return this.toPublicUser(newUser);
  }

  // --- FUNGSI LOGIN ---
  async login(payload: LoginPayload) {
    const email = payload.email.trim().toLowerCase();
    const user = await this.prisma.user.findUnique({ where: { email } });

    if (!user || !user.isActive) {
      throw new UnauthorizedException('Email atau password tidak valid.');
    }

    const isPasswordValid = await bcrypt.compare(
      payload.password,
      user.password,
    );
    if (!isPasswordValid) {
      throw new UnauthorizedException('Email atau password tidak valid.');
    }

    return {
      accessToken: await this.buildToken(user, 900),
      refreshToken: await this.buildToken(user, 604800),
      user: this.toPublicUser(user),
    };
  }

  // --- FUNGSI REFRESH TOKEN ---
  async refresh(refreshToken: string) {
    if (!refreshToken) {
      throw new UnauthorizedException('Refresh token wajib diisi.');
    }

    try {
      const payload = await this.jwtService.verifyAsync<JwtPayload>(
        refreshToken,
        {
          secret: JWT_SECRET,
        },
      );

      const user = await this.prisma.user.findUnique({
        where: { id: payload.sub },
      });
      if (!user || !user.isActive) {
        throw new UnauthorizedException(
          'User tidak ditemukan atau tidak aktif.',
        );
      }

      return {
        accessToken: await this.buildToken(user, 900),
        refreshToken: await this.buildToken(user, 604800),
      };
    } catch {
      throw new UnauthorizedException(
        'Refresh token tidak valid atau kadaluarsa.',
      );
    }
  }

  // --- FUNGSI GOOGLE LOGIN ---
  async googleLogin(idToken: string) {
    try {
      const decodedToken = (await admin
        .auth()
        .verifyIdToken(idToken)) as FirebaseDecodedToken;
      const { email, name, picture } = decodedToken;

      if (!email) {
        throw new BadRequestException(
          'Email tidak ditemukan dalam token Google.',
        );
      }

      let user = await this.prisma.user.findUnique({
        where: { email: email.toLowerCase() },
      });

      if (!user) {
        user = await this.prisma.user.create({
          data: {
            email: email.toLowerCase(),
            name: name || 'Google User',
            password: '',
            role: UserRole.USER,
            isActive: true,
            avatar: picture,
          },
        });
      } else if (!user.isActive) {
        throw new UnauthorizedException('Akun tidak aktif.');
      }

      return {
        accessToken: await this.buildToken(user, 900),
        refreshToken: await this.buildToken(user, 604800),
        user: this.toPublicUser(user),
      };
    } catch (error) {
      if (
        error instanceof BadRequestException ||
        error instanceof UnauthorizedException
      ) {
        throw error;
      }
      throw new UnauthorizedException('Token Google tidak valid.');
    }
  }

  async getProfile(userId: string) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
    });

    if (!user || !user.isActive) {
      throw new UnauthorizedException('User tidak ditemukan atau tidak aktif.');
    }

    return this.toPublicUser(user);
  }

  // --- FUNGSI UPDATE PROFILE BARU ---
  async updateProfile(userId: string, data: UpdateProfilePayload) {
    const nextName = data.name?.trim();
    if (data.name !== undefined && !nextName) {
      throw new BadRequestException('Nama tidak boleh kosong.');
    }

    const updateData: any = {};
    if (nextName !== undefined) {
      updateData.name = nextName;
    }
    if (data.avatar !== undefined) {
      updateData.avatar = data.avatar;
    }
    if (data.phone !== undefined) {
      updateData.phone = data.phone?.trim() || null;
    }
    if (data.institution !== undefined) {
      updateData.institution = data.institution?.trim() || null;
    }

    const updatedUser = await this.prisma.user.update({
      where: { id: userId },
      data: updateData,
    });

    return this.toPublicUser(updatedUser);
  }

  // --- FUNGSI DEFAULT ADMIN ---
  async ensureDefaultAdmin() {
    const email = 'admin@ews.com';
    const existing = await this.prisma.user.findUnique({ where: { email } });

    if (existing) {
      return;
    }

    const hashedPassword = await bcrypt.hash('admin123', 10);

    await this.prisma.user.create({
      data: {
        email,
        password: hashedPassword,
        name: 'Admin EWS',
        role: UserRole.ADMIN,
        isActive: true,
      },
    });
  }

  // --- HELPER PUBLIC USER ---
  private toPublicUser(user: PublicUserFields) {
    return {
      id: user.id,
      email: user.email,
      name: user.name,
      role: user.role,
      avatar: user.avatar ?? null,
      institution: user.institution ?? null,
      phone: user.phone ?? null,
    };
  }

  // --- HELPER BUILD TOKEN ---
  private async buildToken(
    user: UserWithTokenFields,
    expiresInSeconds: number,
  ) {
    const payload: JwtPayload = {
      sub: user.id,
      email: user.email,
      role: user.role,
    };
    return this.jwtService.signAsync(payload, {
      expiresIn: expiresInSeconds,
    });
  }
}
