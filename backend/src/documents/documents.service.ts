import { Injectable } from '@nestjs/common';

@Injectable()
export class DocumentsService {
    async generateInventoryDocx(reportId: string, establishmentId: string) {
    // Заглушка – вернуть пустой буфер
    return Buffer.from('Fake DOCX');
    }
}