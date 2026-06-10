import { Entity, PrimaryGeneratedColumn, Column, ManyToOne, JoinColumn } from 'typeorm';
import { RequestEntity } from './request.entity';

@Entity('request_items')
export class RequestItem {
    @PrimaryGeneratedColumn('uuid')
    id: string;

    @Column()
    productName: string;

    @Column('decimal')
    quantity: number;

    @Column()
    unit: string;

    @Column({ nullable: true })
    comment: string;

    @ManyToOne(() => RequestEntity, { onDelete: 'CASCADE' })
    @JoinColumn({ name: 'requestId' })
    request: RequestEntity;

    @Column()
    requestId: string;
}