import { CanActivate, ExecutionContext, Injectable } from '@nestjs/common';

@Injectable()
export class RolesGuard implements CanActivate {
  canActivate(_context: ExecutionContext): boolean {
    // TODO(TV1/TV5): enforce ADMIN/TEACHER/STUDENT route policies.
    return true;
  }
}
