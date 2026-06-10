import { Controller, Get, Post, Body, UseGuards } from '@nestjs/common';
import { RequestsService } from './requests.service';
import { EstablishmentGuard } from '../common/guards/establishment.guard';
import { CurrentUser } from '../common/decorators/current-user.decorator';

@Controller('requests')
@UseGuards(EstablishmentGuard)
export class RequestsController {
    constructor(private readonly service: RequestsService) {}

    @Get()
    findAll(@CurrentUser('establishmentId') establishmentId: string) {
    return this.service.findAll(establishmentId);
    }

    @Post()
    create(
    @Body() dto: { items: { productName: string; quantity: number; unit: string; comment?: string }[] },
    @CurrentUser('establishmentId') establishmentId: string,
    ) {
    return this.service.create(establishmentId, dto.items);
    }
}