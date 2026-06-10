import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { InventoryReport } from './entities/inventory-report.entity';
import { InventoryItem } from './entities/inventory-item.entity';

@Injectable()
export class InventoryService {
    constructor(
    @InjectRepository(InventoryReport) private reportRepo: Repository<InventoryReport>,
    @InjectRepository(InventoryItem) private itemRepo: Repository<InventoryItem>,
    ) {}

    findAll(establishmentId: string) {
    return this.reportRepo.find({ where: { establishmentId }, relations: ['items'] });
    }

    async create(establishmentId: string, items: { productName: string; remaining: number; unit: string }[]) {
    const report = this.reportRepo.create({ establishmentId });
    await this.reportRepo.save(report);

    // Передаём массив объектов в create, чтобы получить массив сущностей
    const reportItems = this.itemRepo.create(
        items.map(i => ({ ...i, reportId: report.id })),
    );
    await this.itemRepo.save(reportItems);
    return report;
    }
}