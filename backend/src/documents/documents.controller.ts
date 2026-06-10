import { Controller, Post, Body, Res, UseGuards } from '@nestjs/common';
import { Response } from 'express';
import { DocumentsService } from './documents.service';
import { EstablishmentGuard } from '../common/guards/establishment.guard';
import { CurrentUser } from '../common/decorators/current-user.decorator';

@Controller('documents')
@UseGuards(EstablishmentGuard)
export class DocumentsController {
    constructor(private docService: DocumentsService) {}

    @Post('generate-docx')
    async generateDocx(
    @Body() body: { reportId: string },
    @CurrentUser('establishmentId') establishmentId: string,
    @Res() res: Response,
    ) {
    const buffer = await this.docService.generateInventoryDocx(body.reportId, establishmentId);
    res.set({
        'Content-Type': 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
        'Content-Disposition': `attachment; filename=inventory-${body.reportId}.docx`,
    });
    res.send(buffer);
    }
}