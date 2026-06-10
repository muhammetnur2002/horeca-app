import { Injectable } from '@nestjs/common';

@Injectable()
export class SyncService {
    async applyChanges(establishmentId: string, changes: any) {
    console.log('Received changes from establishment', establishmentId, changes);
    return { success: true };
    }

    async getChangesSince(establishmentId: string, since: Date) {
    return [];
    }
}