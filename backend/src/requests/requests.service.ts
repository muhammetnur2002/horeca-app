import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { RequestEntity } from './entities/request.entity';
import { RequestItem } from './entities/request-item.entity';

@Injectable()
export class RequestsService {
    constructor(
    @InjectRepository(RequestEntity) private requestRepo: Repository<RequestEntity>,
    @InjectRepository(RequestItem) private itemRepo: Repository<RequestItem>,
    ) {}

    findAll(establishmentId: string) {
    return this.requestRepo.find({
        where: { establishmentId },
        relations: ['items'],
    });
    }

    async create(establishmentId: string, items: { productName: string; quantity: number; unit: string; comment?: string }[]) {
    const request = this.requestRepo.create({
        establishmentId,
        messageText: items.map(i => `${i.productName} - ${i.quantity} ${i.unit}`).join('\n'),
    });
    await this.requestRepo.save(request);

    // Передаём массив объектов в create
    const requestItems = this.itemRepo.create(
        items.map(i => ({ ...i, requestId: request.id })),
    );
    await this.itemRepo.save(requestItems);
    return request;
    }
}