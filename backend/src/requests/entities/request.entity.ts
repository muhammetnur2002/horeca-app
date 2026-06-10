import { Entity, PrimaryGeneratedColumn, Column, ManyToOne, JoinColumn, OneToMany } from 'typeorm';
import { Establishment } from '../../establishments/entities/establishment.entity';
import { RequestItem } from './request-item.entity';

@Entity('requests')
export class RequestEntity {
    @PrimaryGeneratedColumn('uuid')
    id: string;

    @Column({ nullable: true })
    messageText: string;

    @Column('text', { array: true, nullable: true })
    sentVia: string[];

    @Column({ type: 'timestamptz', default: () => 'now()' })
    createdAt: Date;

    @ManyToOne(() => Establishment, { onDelete: 'CASCADE' })
    @JoinColumn({ name: 'establishmentId' })
    establishment: Establishment;

    @Column()
    establishmentId: string;

    @OneToMany(() => RequestItem, item => item.request, { cascade: true })
    items: RequestItem[];
}