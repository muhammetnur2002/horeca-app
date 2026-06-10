import { Controller, Get, Post, Body, UseGuards } from '@nestjs/common';
import { InventoryService } from './inventory.service';
import { EstablishmentGuard } from '../common/guards/establishment.guard';
import { CurrentUser } from '../common/decorators/current-user.decorator';

@Controller('inventory')
@UseGuards(EstablishmentGuard)
export class InventoryController {
    constructor(private readonly service: InventoryService) {}

    @Get()
    findAll(@CurrentUser('establishmentId') establishmentId: string) {
    return this.service.findAll(establishmentId);
    }

    @Post()
    create(
    @Body() dto: { items: { productName: string; remaining: number; unit: string }[] },
    @CurrentUser('establishmentId') establishmentId: string,
    ) {
    return this.service.create(establishmentId, dto.items);
    }
}