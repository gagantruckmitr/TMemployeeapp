<?php

namespace App\Imports;

use App\Models\Trucklist;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use Maatwebsite\Excel\Concerns\ToModel;
use Maatwebsite\Excel\Concerns\WithHeadingRow;

class TrucksImport implements ToModel, WithHeadingRow
{
    public function model(array $row)
    {
        // Save the Trucklist record first to generate the ID
        $truck = Trucklist::create([
            'brand_id'                => $row['brand_id'] ?? null,
            'oem_name'                => $row['oem_name'] ?? null,
            'slug'                    => $row['slug'] ?? '',
            'Vehicle_type'            => $row['vehicle_type'] ?? null,
            'Product_specification'   => $row['product_specification'] ?? null,
            'Vehicle_model'           => $row['vehicle_model'] ?? null,
            'Engine_make'             => $row['engine_make'] ?? null,
            'Engine_model'            => $row['engine_model'] ?? null,
            'Engine_HP'               => $row['engine_hp'] ?? null,
            'Engine_capacity'         => $row['engine_capacity'] ?? null,
            'No_of_cylinders'         => $row['no_of_cylinders'] ?? null,
            'MAX_Engine_output'       => $row['max_engine_output'] ?? null,
            'MAX_Torque'              => $row['max_torque'] ?? null,
            'OD_of_clutch_lining'     => $row['od_of_clutch_lining'] ?? null,
            'Clutch_type'             => $row['clutch_type'] ?? null,
            'Type_of_actuation'       => $row['type_of_actuation'] ?? null,
            'Gear_Box_Model'          => $row['gear_box_model'] ?? null,
            'No_of_gears'             => $row['no_of_gears'] ?? null,
            'Min_Turning_circle_dia'  => $row['min_turning_circle_dia'] ?? null,
            'Wheel_base'              => $row['wheel_base'] ?? null,
            'Overall_Length'          => $row['overall_length'] ?? null,
            'Overall_Height'          => $row['overall_height'] ?? null,
            'Overall_Width'           => $row['overall_width'] ?? null,
            'Ground_clearance'        => $row['ground_clearance'] ?? null,
            'Max_Permissible_GVW'     => $row['max_permissible_gvw'] ?? null,
            'Fuel_tank_Capacity'      => $row['fuel_tank_capacity'] ?? null,
            'Steering_type'           => $row['steering_type'] ?? null,
            'Suspension_Type_Front'   => $row['suspension_type_front'] ?? null,
            'Suspension_Type_Rear'    => $row['suspension_type_rear'] ?? null,
            'Wheels'                  => $row['wheels'] ?? null,
            'No_of_tyres'             => $row['no_of_tyres'] ?? null,
            'Battery'                 => $row['battery'] ?? null,
            'Brakes_type'             => $row['brakes_type'] ?? null,
            'Parking_brake'           => $row['parking_brake'] ?? null,
            'Auxiliary_Braking_System'=> $row['auxiliary_braking_system'] ?? null,
            'Frame_type'              => $row['frame_type'] ?? null,
            'Diesel_Exhaust_Fluid'    => $row['diesel_exhaust_fluid'] ?? null,
            'Front_axle_Type'         => $row['front_axle_type'] ?? null,
            'Rear_axle_Model'         => $row['rear_axle_model'] ?? null,
            'Rear_axle_Ratio'         => $row['rear_axle_ratio'] ?? null,
            'Cabin_type'              => $row['cabin_type'] ?? null,
            'Standard_features'       => $row['standard_features'] ?? null,
            'Maximum_gradebility'     => $row['maximum_gradebility'] ?? null,
            'Price_Range'             => $row['price_range'] ?? null,
            'max_price'               => $row['max_price'] ?? null,
            'fule_type'               => $row['fule_type'] ?? null,
            'Gvm'                     => $row['gvm'] ?? null,
            'Description'             => $row['description'] ?? null,
            'tyres_count'             => $row['tyres_count'] ?? null,
            'images'                  => 'images/'.$row['images'] ?? null,
            'brochure_pdf'                  => 'N/A',
            'add_application'         => isset($row['add_application']) && is_array($row['add_application']) 
                                         ? json_encode($row['add_application']) 
                                         : ($row['add_application'] ?? null),
            'compare_id'             => $row['compare_id'] ?? null,
        ]);

        // Handle multiple images
        if (isset($row['mul_images']) && !empty($row['mul_images'])) {
            $imagePaths = explode(',', $row['mul_images']); // Split the images
            $imageData = [];

            foreach ($imagePaths as $imagePath) {
                $imageData[] = [
                    'truck_id'    => $truck->id,
                    'multi_image' => 'images/'.trim($imagePath), // Trim spaces
                    'created_at'  => now(),
                    'updated_at'  => now(),
                ];
            }

            // Bulk insert into the truck_images table
            DB::table('truck_images')->insert($imageData);
        }

        return $truck;
    }
}