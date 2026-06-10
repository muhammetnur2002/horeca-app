import { Controller, Get, Post, Body, Query, UseGuards } from '@nestjs/common';
import { CategoriesService } from './categories.service';
import { EstablishmentGuard } from '../common/guards/establishment.guard';
import { CurrentUser } from '../common/decorators/current-user.decorator';

@Controller('categories')
@UseGuards(EstablishmentGuard)
export class CategoriesController {
    constructor(private readonly service: CategoriesService) {}

    @Get()
    findAll(
    @CurrentUser('establishmentId') establishmentId: string,
    @Query('departmentId') departmentId?: string,
    ) {
    return this.service.findAll(establishmentId, departmentId);
    }

    @Post()
    create(
    @Body() dto: { name: string; departmentId: string },
    @CurrentUser('establishmentId') establishmentId: string,
    ) {
    return this.service.create(establishmentId, dto.name, dto.departmentId);
    }
}