import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { InventoryReport } from './entities/inventory-report.entity';
import { InventoryItem } from './entities/inventory-item.entity';
import { InventoryController } from './inventory.controller';
import { InventoryService } from './inventory.service';

@Module({
    imports: [TypeOrmModule.forFeature([InventoryReport, InventoryItem])],
    controllers: [InventoryController],
    providers: [InventoryService],
})
export class InventoryModule {}