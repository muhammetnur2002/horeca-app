import { Entity, PrimaryGeneratedColumn, Column, ManyToOne, JoinColumn } from 'typeorm';
import { InventoryReport } from './inventory-report.entity';

@Entity('inventory_items')
export class InventoryItem {
    @PrimaryGeneratedColumn('uuid')
    id: string;

    @Column()
    productName: string;

    @Column('decimal')
    remaining: number;

    @Column()
    unit: string;

    @ManyToOne(() => InventoryReport, { onDelete: 'CASCADE' })
    @JoinColumn({ name: 'reportId' })
    report: InventoryReport;

    @Column()
    reportId: string;
}