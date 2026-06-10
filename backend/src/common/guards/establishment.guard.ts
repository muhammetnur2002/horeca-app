import { CanActivate, ExecutionContext, Injectable } from '@nestjs/common';

@Injectable()
export class EstablishmentGuard implements CanActivate {
    canActivate(context: ExecutionContext): boolean {
    // Пока разрешаем все запросы (MVP)
    return true;
    }
}