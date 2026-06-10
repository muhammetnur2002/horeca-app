import { Entity, PrimaryGeneratedColumn, Column, ManyToOne, JoinColumn, OneToMany } from 'typeorm';
import { Establishment } from '../../establishments/entities/establishment.entity';
import { InventoryItem } from './inventory-item.entity';

@Entity('inventory_reports')
export class InventoryReport {
    @PrimaryGeneratedColumn('uuid')
    id: string;

    @Column({ type: 'timestamptz', default: () => 'now()' })
    createdAt: Date;

    @ManyToOne(() => Establishment, { onDelete: 'CASCADE' })
    @JoinColumn({ name: 'establishmentId' })
    establishment: Establishment;

    @Column()
    establishmentId: string;

    @OneToMany(() => InventoryItem, item => item.report, { cascade: true })
    items: InventoryItem[];
}