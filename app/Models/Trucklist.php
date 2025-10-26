<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Trucklist extends Model
{
    use HasFactory;
	protected $table = 'trucklist';
	protected $fillable  = [
        'oem_name',
        'slug',
        'Vehicle_type',
        'Product_specification',
        'Vehicle_model',
        'Engine_make',
        'Engine_model',
        'Engine_HP',
        'Engine_capacity',
        'No_of_cylinders',
        'MAX_Engine_output',
        'MAX_Torque',
        'OD_of_clutch_lining',
        'Clutch_type',
        'Type_of_actuation',
        'Gear_Box_Model',
        'No_of_gears',
        'Min_Turning_circle_dia',
        'Wheel_base',
        'Overall_Length',
        'Overall_Height',
        'Overall_Width',
        'Ground_clearance',
        'Max_Permissible_GVW',
        'Fuel_tank_Capacity',
        'Steering_type',
        'Suspension_Type_Front',
        'Suspension_Type_Rear',
        'Wheels',
        'No_of_tyres',
        'Battery',
        'Brakes_type',
        'Parking_brake',
        'Auxiliary_Braking_System',
        'Frame_type',
        'Diesel_Exhaust_Fluid',
        'Front_axle_Type',
        'Rear_axle_Model',
        'Rear_axle_Ratio',
        'Cabin_type',
        'Standard_features',
        'Maximum_gradebility',
        'Price_Range',
        'images',
        'Description',
        'fule_type',
        'Gvm',
        'add_application',
        'brochure_pdf',
        'tyres_count',
        'max_price',
        'brand_id'
    ];
}
