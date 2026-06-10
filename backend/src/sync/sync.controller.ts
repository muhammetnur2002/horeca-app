import { Controller, Post, Body, Get, Query, UseGuards } from '@nestjs/common';
import { SyncService } from './sync.service';
import { EstablishmentGuard } from '../common/guards/establishment.guard';
import { CurrentUser } from '../common/decorators/current-user.decorator';

@Controller('sync')
@UseGuards(EstablishmentGuard)
export class SyncController {
    constructor(private syncService: SyncService) {}

    @Post('push')
    push(@CurrentUser('establishmentId') establishmentId: string, @Body() changes: any) {
    return this.syncService.applyChanges(establishmentId, changes);
    }

    @Get('pull')
    pull(@CurrentUser('establishmentId') establishmentId: string, @Query('since') since: string) {
    return this.syncService.getChangesSince(establishmentId, since ? new Date(since) : new Date(0));
    }
}