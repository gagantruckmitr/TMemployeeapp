@include('Admin.layouts.header')
<div class="page-wrapper">
    <div class="content container-fluid">
        <div class="page-header">
            <div class="row">
                <div class="col-sm-12">
                <div class="page-sub-header">
                    <h3 class="page-title">Truck</h3>
                    <ul class="breadcrumb">
					<li class="breadcrumb-item active"><a style="color:white;" class="btn btn-primary" href="{{url('admin/truck-list')}}">List Truck</a></li>
                        <li class="breadcrumb-item active">Add Truck</li>
                    </ul>
                </div>
                </div>
            </div>
        </div>
        
             <div class="row">
                <div class="col-md-12">
                    <div class="card">
                        <div class="card-header">
                            <h5 class="card-title">Edit Truck</h5>
                        </div>
                        @include('Admin.layouts.message')
                        <div class="card-body">
                           <form method="POST" enctype="multipart/form-data">
                            {{ csrf_field() }}
                        
                            @if(isset($truck))
                                @foreach($truck as $t)
                                    <div class="row">
                                        <div class="col-md-3">
                                            <div class="form-group">
                                                <label>Select Brand<span class="login-danger">*</span></label>
                                                <select class="form-control" name="brand_id">
                                                    @foreach ($brand as $value)
                                                        <option value="{{ $value->id }}" {{ $t->brand_id == $value->id ? 'selected' : '' }}>
                                                            {{ $value->name }}
                                                        </option>
                                                    @endforeach
                                            </select>
                                        </div>
                                    </div>
                                    <div class="col-md-3">
                                        <div class="form-group">
                                           <label>OEM Name<span class="login-danger">*</span></label>
                                           <input type="text" name="oem_name" class="form-control" value="{{$t->oem_name}}">
										   
                                        </div>
                                   </div>
                                   <div class="col-md-3">
                                        <div class="form-group">
                                           <label>OEM Name Slug<span class="login-danger">*</span></label>
                                           <input type="text" name="slug" class="form-control" value="{{$t->slug}}">
										   
                                        </div>
                                   </div>
                                   <div class="col-md-3">
                                        <div class="form-group">
                                            <label>Vehicle Type<span class="login-danger">*</span></label>
                                            <select class="form-control" name="Vehicle_type">
                                                <option>Select</option>
                                                @foreach ($Vehicletype as $key => $value)
                                                    <option value="{{ $value->vehicle_name }}" {{ $t->Vehicle_type == $value->vehicle_name ? 'selected' : '' }}>
                                                        {{ $value->vehicle_name }}
                                                    </option>
                                                @endforeach 
                                            </select>
                                        </div>
                                    </div>

                                   <div class="col-md-3">
                                        <div class="form-group">
                                           <label>Product Specification<span class="login-danger">*</span> </label>
                                           <input type="text" name="Product_specification" class="form-control" value="{{$t->Product_specification}}">
										   
                                        </div>
                                   </div>
                                    <div class="col-md-3">
                                        <div class="form-group">
                                           <label>Vehicle Model<span class="login-danger">*</span></label>
                                           <input type="text" name="Vehicle_model" class="form-control" value="{{$t->Vehicle_model}}">
										   
                                        </div>
                                   </div>
                                   <div class="col-md-3">
                                        <div class="form-group">
                                           <label>Engine make<span class="login-danger">*</span></label>
                                           <input type="text" name="Engine_make" class="form-control" value="{{$t->Engine_make}}">
										   
                                        </div>
                                   </div>
                                    <div class="col-md-3">
                                        <div class="form-group">
                                           <label>Engine model<span class="login-danger">*</span></label>
                                           <input type="text" name="Engine_model" class="form-control" value="{{$t->Engine_model}}">
										   
                                        </div>
                                   </div>
                                   <div class="col-md-3">
                                        <div class="form-group">
                                           <label>Engine HP<span class="login-danger">*</span></label>
                                           <input type="text" name="Engine_HP" class="form-control" value="{{$t->Engine_HP}}">
										   
                                        </div>
                                   </div>
                                    <div class="col-md-3">
                                        <div class="form-group">
                                           <label>Engine capacity(cc)<span class="login-danger">*</span></label>
                                           <input type="text" name="Engine_capacity" class="form-control" value="{{$t->Engine_capacity}}">
										   
                                        </div>
                                   </div>
                                   <div class="col-md-3">
                                        <div class="form-group">
                                           <label>No of cylinders<span class="login-danger">*</span></label>
                                           <input type="text" name="No_of_cylinders" class="form-control" value="{{$t->No_of_cylinders}}">
										   
                                        </div>
                                   </div>
                                    <div class="col-md-3">
                                        <div class="form-group">
                                           <label>MAX Engine output<span class="login-danger">*</span></label>
                                           <input type="text" name="MAX_Engine_output" class="form-control" value="{{$t->MAX_Engine_output}}">
										   
                                        </div>
                                   </div>
                                   <div class="col-md-3">
                                        <div class="form-group">
                                           <label> MAX. Torque<span class="login-danger">*</span></label>
                                           <input type="text" name="MAX_Torque" class="form-control" value="{{$t->MAX_Torque}}">
										   
                                        </div>
                                   </div>
                                    <div class="col-md-3">
                                        <div class="form-group">
                                           <label>O.D of clutch lining (mm)<span class="login-danger">*</span></label>
                                           <input type="text" name="OD_of_clutch_lining" class="form-control" value="{{$t->OD_of_clutch_lining}}">
										   
                                        </div>
                                   </div>
                                   <div class="col-md-3">
                                        <div class="form-group">
                                           <label>Clutch Type<span class="login-danger">*</span></label>
                                           <input type="text" name="Clutch_type" class="form-control" value="{{$t->Clutch_type}}">
										   
                                        </div>
                                   </div>
                                    <div class="col-md-3">
                                        <div class="form-group">
                                           <label>Type of actuation<span class="login-danger">*</span></label>
                                           <input type="text" name="Type_of_actuation" class="form-control" value="{{$t->Type_of_actuation}}">
										   
                                        </div>
                                   </div>
                                   <div class="col-md-3">
                                        <div class="form-group">
                                           <label>Gear Box Model<span class="login-danger">*</span></label>
                                           <input type="text" name="Gear_Box_Model" class="form-control" value="{{$t->Gear_Box_Model}}">
										   
                                        </div>
                                   </div>
                                    <div class="col-md-3">
                                        <div class="form-group">
                                           <label>No. of gears<span class="login-danger">*</span></label>
                                           <input type="text" name="No_of_gears" class="form-control" value="{{$t->No_of_gears}}">
										   
                                        </div>
                                   </div>
                                   <div class="col-md-3">
                                        <div class="form-group">
                                           <label>Min. Turning circle dia (mm)<span class="login-danger">*</span></label>
                                           <input type="text" name="Min_Turning_circle_dia" class="form-control" value="{{$t->Min_Turning_circle_dia}}">
										  
                                        </div>
                                   </div>
                                    <div class="col-md-3">
                                        <div class="form-group">
                                           <label>Wheel base (mm)<span class="login-danger">*</span></label>
                                           <input type="text" name="Wheel_base" class="form-control" value="{{$t->Wheel_base}}">
										   
                                        </div>
                                   </div>
                                   <div class="col-md-3">
                                        <div class="form-group">
                                           <label>Overall Length (mm)<span class="login-danger">*</span></label>
                                           <input type="text" name="Overall_Length" class="form-control" value="{{$t->Overall_Length}}">
										   
                                        </div>
                                   </div>
                                    <div class="col-md-3">
                                        <div class="form-group">
                                           <label>Overall Height (mm)<span class="login-danger">*</span></label>
                                           <input type="text" name="Overall_Height" class="form-control" value="{{$t->Overall_Height}}">
										   
                                        </div>
                                   </div>
                                   <div class="col-md-3">
                                        <div class="form-group">
                                           <label>Overall Width (mm)<span class="login-danger">*</span></label>
                                           <input type="text" name="Overall_Width" class="form-control" value="{{$t->Overall_Width}}">
										  
                                        </div>
                                   </div>
                                    <div class="col-md-3">
                                        <div class="form-group">
                                           <label>Ground clearance (mm)<span class="login-danger">*</span></label>
                                           <input type="text" name="Ground_clearance" class="form-control" value="{{$t->Ground_clearance}}">
										  
                                        </div>
                                   </div>
                                   <div class="col-md-3">
                                        <div class="form-group">
                                           <label>Max. Permissible GVW<span class="login-danger">*</span></label>
                                           <input type="text" name="Max_Permissible_GVW" class="form-control" value="{{$t->Max_Permissible_GVW}}">
										   
                                        </div>
                                   </div>
                                    <div class="col-md-3">
                                        <div class="form-group">
                                           <label>Fuel tank Capacity<span class="login-danger">*</span></label>
                                           <input type="text" name="Fuel_tank_Capacity" class="form-control" value="{{$t->Fuel_tank_Capacity}}">
										  
                                        </div>
                                   </div>
                                   <div class="col-md-3">
                                        <div class="form-group">
                                           <label>Steering Type<span class="login-danger">*</span></label>
                                           <input type="text" name="Steering_type" class="form-control" value="{{$t->Steering_type}}">
										   
                                        </div>
                                   </div>
                                    <div class="col-md-3">
                                        <div class="form-group">
                                           <label>Suspension Type  Front<span class="login-danger">*</span></label>
                                           <input type="text" name="Suspension_Type_Front" class="form-control" value="{{$t->Suspension_Type_Front}}">
										   
                                        </div>
                                   </div>
                                   <div class="col-md-3">
                                        <div class="form-group">
                                           <label>Suspension Type  Rear<span class="login-danger">*</span></label>
                                           <input type="text" name="Suspension_Type_Rear" class="form-control" value="{{$t->Suspension_Type_Rear}}">
										  
                                        </div>
                                   </div>
                                    <div class="col-md-3">
                                        <div class="form-group">
                                           <label>Wheels<span class="login-danger">*</span></label>
                                           <input type="text" name="Wheels" class="form-control" value="{{$t->Wheels}}">
										   
                                        </div>
                                   </div>
                                   <div class="col-md-3">
                                        <div class="form-group">
                                            <label>No. of Tyres<span class="login-danger">*</span></label>
                                            <select class="form-control" name="No_of_tyres">
                                                <option>Select</option>
                                                @foreach ($TyresCount as $key => $value)
                                                    <option value="{{ $value->tyres_type }}" 
                                                        {{ $t->No_of_tyres == $value->tyres_type ? 'selected' : '' }}>
                                                        {{ $value->tyres_type }}
                                                    </option>
                                                @endforeach 
                                            </select>
                                        </div>
                                    </div>

                                    <div class="col-md-3">
                                        <div class="form-group">
                                           <label>Battery<span class="login-danger">*</span></label>
                                           <input type="text" name="Battery" class="form-control" value="{{$t->Battery}}">
										  
                                        </div>
                                   </div>
                                   <div class="col-md-3">
                                        <div class="form-group">
                                           <label>Brakes type<span class="login-danger">*</span></label>
                                           <input type="text" name="Brakes_type" class="form-control" value="{{$t->Brakes_type}}">
										   
                                        </div>
                                   </div>
                                    <div class="col-md-3">
                                        <div class="form-group">
                                           <label>Parking brake<span class="login-danger">*</span></label>
                                           <input type="text" name="Parking_brake" class="form-control" value="{{$t->Parking_brake}}">
										   
                                        </div>
                                   </div>
                                   <div class="col-md-3">
                                        <div class="form-group">
                                           <label>Auxiliary Braking System<span class="login-danger">*</span> </label>
                                           <input type="text" name="Auxiliary_Braking_System" class="form-control" value="{{$t->Auxiliary_Braking_System}}">
										   
                                        </div>
                                   </div>
                                    <div class="col-md-3">
                                        <div class="form-group">
                                           <label>Frame type<span class="login-danger">*</span></label>
                                           <input type="text" name="Frame_type" class="form-control" value="{{$t->Frame_type}}">
										   
                                        </div>
                                   </div>
                                   <div class="col-md-3">
                                        <div class="form-group">
                                           <label>Diesel Exhaust Fluid (DEF)<span class="login-danger">*</span></label>
                                           <input type="text" name="Diesel_Exhaust_Fluid" class="form-control" value="{{$t->Diesel_Exhaust_Fluid}}">
										   
                                        </div>
                                   </div>
                                    <div class="col-md-3">
                                        <div class="form-group">
                                           <label>Front axle Type<span class="login-danger">*</span></label>
                                           <input type="text" name="Front_axle_Type" class="form-control" value="{{$t->Front_axle_Type}}">
										  
                                        </div>
                                   </div>
                                   <div class="col-md-3">
                                        <div class="form-group">
                                           <label>Rear axle Model<span class="login-danger">*</span></label>
                                           <input type="text" name="Rear_axle_Model" class="form-control" value="{{$t->Rear_axle_Model}}">
										   
                                        </div>
                                   </div>
                                    <div class="col-md-3">
                                        <div class="form-group">
                                           <label>Rear axle Ratio<span class="login-danger">*</span></label>
                                           <input type="text" name="Rear_axle_Ratio" class="form-control" value="{{$t->Rear_axle_Ratio}}">
										   
                                        </div>
                                   </div>
                                   <div class="col-md-3">
                                        <div class="form-group">
                                           <label>Cabin type<span class="login-danger">*</span></label>
                                           <input type="text" name="Cabin_type" class="form-control" value="{{$t->Cabin_type}}">
										   
                                        </div>
                                   </div>
                                    <div class="col-md-3">
                                        <div class="form-group">
                                           <label>Standard features<span class="login-danger">*</span></label>
                                           <input type="text" name="Standard_features" class="form-control" value="{{$t->Standard_features}}">
										   
                                        </div>
                                   </div>
                                   <div class="col-md-3">
                                        <div class="form-group">
                                           <label>Maximum gradebility<span class="login-danger">*</span></label>
                                           <input type="text" name="Maximum_gradebility" class="form-control" value="{{$t->Maximum_gradebility}}">
										   
                                        </div>
                                   </div>
                                   <div class="col-md-3">
                                        <div class="form-group">
                                           <label>Price Range<span class="login-danger">*</span></label>
                                           <input type="text" name="Price_Range" class="form-control" value="{{$t->Price_Range}}">
										  
                                        </div>
                                   </div>
                                   <div class="col-md-3">
                                        <div class="form-group">
                                           <label>Max Price<span class="login-danger">*</span></label>
                                           <input type="text" name="max_price" class="form-control" value="{{$t->max_price}}">
										   @if($errors->has('max_price'))
											  <span class="text-danger">{{ $errors->first('max_price') }}</span>
											@endif
                                        </div>
                                   </div>
                                  <div class="col-md-3">
                                        <div class="form-group">
                                            <label>Fuel Type<span class="login-danger">*</span></label>
                                            <select class="form-control" name="fule_type">
                                                <option>Select</option>
                                                @foreach ($Fueltype as $key => $value)
                                                    <option value="{{ $value->fuel_type_name }}" 
                                                        {{ $t->fule_type == $value->fuel_type_name ? 'selected' : '' }}>
                                                        {{ $value->fuel_type_name }}
                                                    </option>
                                                @endforeach 
                                            </select>
                                        </div>
                                    </div>

                                        <div class="col-md-3">
                                            <div class="form-group">
                                                <label>Select GVM<span class="login-danger">*</span></label>
                                                <select class="form-control" name="Gvm">
                                                    <option>Select</option>
                                                    @foreach ($Gvm as $key => $value)
                                                        <option value="{{ $value->gvm_name }}" 
                                                            {{ isset($t->Gvm) && $t->Gvm == $value->gvm_name ? 'selected' : '' }}>
                                                            {{ $value->gvm_name }}
                                                        </option>
                                                    @endforeach 
                                                </select>
                                            </div>
                                        </div>

                                 <div class="col-md-3">
                                        <div class="form-group">
                                            <label>Vehicle Application<span class="login-danger">*</span></label>
                                            
                                            <?php 
                                            // Decode the JSON stored value safely
                                            $selectedValues = is_string($t->add_application) ? json_decode($t->add_application, true) : [];
                                            $selectedValues = is_array($selectedValues) ? $selectedValues : [];
                                            ?>
                                    
                                            <select class="form-control" name="add_application[]" multiple>
                                                @foreach ($VehicleApplication as $key => $value)
                                                    <option value="{{ $value->vehicle_application_name }}" 
                                                        {{ in_array($value->vehicle_application_name, $selectedValues) ? 'selected' : '' }}>
                                                        {{ $value->vehicle_application_name }}
                                                    </option>
                                                @endforeach 
                                            </select>
                                        </div>
                                    </div>

                                    <div class="col-md-3">
                                        <div class="form-group">
                                           <label>Featured Image<span class="login-danger">*</span> <small>(Size:650 X 373 px)</small></label>
                                           <input type="file" name="images" class="form-control">
										   
                                        </div>
                                   </div>
                                   
                                    
                                   <div class="col-md-6">
                                        <div class="form-group">
                                           <label>Product Gallery <span class="login-danger">*</span> <small>(Size:650 X 373 px)</small></label>
                                           <input type="file" name="multi_image[]" id="multi_image" class="form-control" multiple>
										    
                                        </div>
                                   </div>
                                    <div class="col-md-3">
                                        <div class="form-group">
                                           <label>Truck brochure <span class="login-danger">*</span></label>
                                           <input type="file" name="brochure_pdf" class="form-control">
										   
                                        </div>
                                   </div>
                                    <div class="col-md-6">
                                        <div class="form-group">
                                           <label>Description<span class="login-danger">*</span></label>
                                           <textarea rows="5" cols="5" name="Description" class="form-control" placeholder="Enter message"><?php echo $t->Description; ?></textarea>
										   
                                        </div>
                                   </div>
                                  
                                    <div class="text-start">
                                    <button type="submit" class="btn btn-primary">Update</button>
                                    </div>
                                @endforeach
                                @endif
                            </form>
                        </div>
                    </div>
                </div>
        </div>
</div>
        
@include('Admin.layouts.footer')
