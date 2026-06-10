import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { RequestEntity } from './entities/request.entity';
import { RequestItem } from './entities/request-item.entity';
import { RequestsController } from './requests.controller';
import { RequestsService } from './requests.service';

@Module({
    imports: [TypeOrmModule.forFeature([RequestEntity, RequestItem])],
    controllers: [RequestsController],
    providers: [RequestsService],
})
export class RequestsModule {}