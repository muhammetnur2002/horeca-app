import { Controller, Get, Post, Body, UseGuards } from '@nestjs/common';
import { DepartmentsService } from './departments.service';
import { EstablishmentGuard } from '../common/guards/establishment.guard';
import { CurrentUser } from '../common/decorators/current-user.decorator';

@Controller('departments')
@UseGuards(EstablishmentGuard)
export class DepartmentsController {
    constructor(private readonly service: DepartmentsService) {}

    @Get()
    findAll(@CurrentUser('establishmentId') establishmentId: string) {
    return this.service.findAll(establishmentId);
    }

    @Post()
create(
    @Body() dto: { name: string },
    @CurrentUser() establishmentId: string,
) {
    console.log('establishmentId =', establishmentId, typeof establishmentId);
    return this.service.create(establishmentId, dto.name);
}
}