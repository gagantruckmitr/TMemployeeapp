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
                            <h5 class="card-title">Add Truck</h5>
                        </div>
                        @if(session('success'))
                            <p style="color: green;">{{ session('success') }}</p>
                        @elseif(session('error'))
                            <p style="color: red;">{{ session('error') }}</p>
                        @endif
                        <div class="card-body">
                           <form action="{{url('admin/create_truck')}}" method="POST" enctype="multipart/form-data">
							 {{ csrf_field() }}
                                <div class="row">
                                    <div class="col-md-3">
                                        <div class="form-group">
                                           <label>Select Brand<span class="login-danger">*</span></label>
                                           <select class="form-control" name="brand_id">
                                               @foreach ($brand as $key => $value)
                                               <option></option>
                                               <option value="{{$value->id}}">{{$value->name}}</option>
                                                @endforeach 
                                           </select>
										   
                                        </div>
                                   </div>
                                   <div class="col-md-3">
                                        <div class="form-group">
                                           <label>OEM Name<span class="login-danger">*</span></label>
                                           <input type="text" name="oem_name" class="form-control" value="{{old('oem_name')}}">
										   @if($errors->has('oem_name'))
											  <span class="text-danger">{{ $errors->first('oem_name') }}</span>
											@endif
                                        </div>
                                   </div>
                                   <div class="col-md-3">
                                        <div class="form-group">
                                           <label>OEM Name Slug<span class="login-danger">*</span></label>
                                           <input type="text" name="slug" class="form-control" value="{{old('slug')}}">
										   @if($errors->has('slug'))
											  <span class="text-danger">{{ $errors->first('slug') }}</span>
											@endif
                                        </div>
                                   </div>
                                    <div class="col-md-3">
                                        <div class="form-group">
                                           <label>Vehicle  Type<span class="login-danger">*</span></label>
                                           <select class="form-control" name="Vehicle_type">
                                               <option>Select</option>
                                               @foreach ($Vehicletype as $key => $value)
                                                   <option value="{{$value->vehicle_name}}">{{$value->vehicle_name}}</option>
                                                @endforeach 
                                           </select>
										   @if($errors->has('Vehicle_type'))
											  <span class="text-danger">{{ $errors->first('Vehicle_type') }}</span>
											@endif
                                        </div>
                                   </div>
                                   <div class="col-md-3">
                                        <div class="form-group">
                                           <label>Product Specification<span class="login-danger">*</span> </label>
                                           <input type="text" name="Product_specification" class="form-control" value="{{old('Product_specification')}}">
										   @if($errors->has('Product_specification'))
											  <span class="text-danger">{{ $errors->first('Product_specification') }}</span>
											@endif
                                        </div>
                                   </div>
                                    <div class="col-md-3">
                                        <div class="form-group">
                                           <label>Vehicle Model<span class="login-danger">*</span></label>
                                           <input type="text" name="Vehicle_model" class="form-control" value="{{old('Vehicle_model')}}">
										   @if($errors->has('Vehicle_model'))
											  <span class="text-danger">{{ $errors->first('Vehicle_model') }}</span>
											@endif
                                        </div>
                                   </div>
                                   <div class="col-md-3">
                                        <div class="form-group">
                                           <label>Engine Make<span class="login-danger">*</span></label>
                                           <input type="text" name="Engine_make" class="form-control" value="{{old('Engine_make')}}">
										   @if($errors->has('Engine_make'))
											  <span class="text-danger">{{ $errors->first('Engine_make') }}</span>
											@endif
                                        </div>
                                   </div>
                                    <div class="col-md-3">
                                        <div class="form-group">
                                           <label>Engine Model<span class="login-danger">*</span></label>
                                           <input type="text" name="Engine_model" class="form-control" value="{{old('Engine_model')}}">
										   @if($errors->has('Engine_model'))
											  <span class="text-danger">{{ $errors->first('Engine_model') }}</span>
											@endif
                                        </div>
                                   </div>
                                   <div class="col-md-3">
                                        <div class="form-group">
                                           <label>Engine HP<span class="login-danger">*</span></label>
                                           <input type="text" name="Engine_HP" class="form-control" value="{{old('Engine_HP')}}">
										   @if($errors->has('Engine_HP'))
											  <span class="text-danger">{{ $errors->first('Engine_HP') }}</span>
											@endif
                                        </div>
                                   </div>
                                    <div class="col-md-3">
                                        <div class="form-group">
                                           <label>Engine Capacity(cc)<span class="login-danger">*</span></label>
                                           <input type="text" name="Engine_capacity" class="form-control" value="{{old('Engine_capacity')}}">
										   @if($errors->has('Engine_capacity'))
											  <span class="text-danger">{{ $errors->first('Engine_capacity') }}</span>
											@endif
                                        </div>
                                   </div>
                                   <div class="col-md-3">
                                        <div class="form-group">
                                           <label>No of Cylinders<span class="login-danger">*</span></label>
                                           <input type="text" name="No_of_cylinders" class="form-control" value="{{old('No_of_cylinders')}}">
										   @if($errors->has('No_of_cylinders'))
											  <span class="text-danger">{{ $errors->first('No_of_cylinders') }}</span>
											@endif
                                        </div>
                                   </div>
                                    <div class="col-md-3">
                                        <div class="form-group">
                                           <label>MAX Engine Output<span class="login-danger">*</span></label>
                                           <input type="text" name="MAX_Engine_output" class="form-control" value="{{old('MAX_Engine_output')}}">
										   @if($errors->has('MAX_Engine_output'))
											  <span class="text-danger">{{ $errors->first('MAX_Engine_output') }}</span>
											@endif
                                        </div>
                                   </div>
                                   <div class="col-md-3">
                                        <div class="form-group">
                                           <label> MAX. Torque<span class="login-danger">*</span></label>
                                           <input type="text" name="MAX_Torque" class="form-control" value="{{old('MAX_Torque')}}">
										   @if($errors->has('MAX_Torque'))
											  <span class="text-danger">{{ $errors->first('MAX_Torque') }}</span>
											@endif
                                        </div>
                                   </div>
                                    <div class="col-md-3">
                                        <div class="form-group">
                                           <label>O.D of Clutch Lining (mm)<span class="login-danger">*</span></label>
                                           <input type="text" name="OD_of_clutch_lining" class="form-control" value="{{old('OD_of_clutch_lining')}}">
										   @if($errors->has('OD_of_clutch_lining'))
											  <span class="text-danger">{{ $errors->first('OD_of_clutch_lining') }}</span>
											@endif
                                        </div>
                                   </div>
                                   <div class="col-md-3">
                                        <div class="form-group">
                                           <label>Clutch Type<span class="login-danger">*</span></label>
                                           <input type="text" name="Clutch_type" class="form-control" value="{{old('Clutch_type')}}">
										   @if($errors->has('Clutch_type'))
											  <span class="text-danger">{{ $errors->first('Clutch_type') }}</span>
											@endif
                                        </div>
                                   </div>
                                    <div class="col-md-3">
                                        <div class="form-group">
                                           <label>Type of Actuation<span class="login-danger">*</span></label>
                                           <input type="text" name="Type_of_actuation" class="form-control" value="{{old('Type_of_actuation')}}">
										   @if($errors->has('Type_of_actuation'))
											  <span class="text-danger">{{ $errors->first('Type_of_actuation') }}</span>
											@endif
                                        </div>
                                   </div>
                                   <div class="col-md-3">
                                        <div class="form-group">
                                           <label>Gear Box Model<span class="login-danger">*</span></label>
                                           <input type="text" name="Gear_Box_Model" class="form-control" value="{{old('Gear_Box_Model')}}">
										   @if($errors->has('Gear_Box_Model'))
											  <span class="text-danger">{{ $errors->first('Gear_Box_Model') }}</span>
											@endif
                                        </div>
                                   </div>
                                    <div class="col-md-3">
                                        <div class="form-group">
                                           <label>No. of Gears<span class="login-danger">*</span></label>
                                           <input type="text" name="No_of_gears" class="form-control" value="{{old('No_of_gears')}}">
										   @if($errors->has('No_of_gears'))
											  <span class="text-danger">{{ $errors->first('No_of_gears') }}</span>
											@endif
                                        </div>
                                   </div>
                                   <div class="col-md-3">
                                        <div class="form-group">
                                           <label>Min. Turning Circle Dia (mm)<span class="login-danger">*</span></label>
                                           <input type="text" name="Min_Turning_circle_dia" class="form-control" value="{{old('Min_Turning_circle_dia')}}">
										   @if($errors->has('Min_Turning_circle_dia'))
											  <span class="text-danger">{{ $errors->first('Min_Turning_circle_dia') }}</span>
											@endif
                                        </div>
                                   </div>
                                    <div class="col-md-3">
                                        <div class="form-group">
                                           <label>Wheel Base (mm)<span class="login-danger">*</span></label>
                                           <input type="text" name="Wheel_base" class="form-control" value="{{old('Wheel_base')}}">
										   @if($errors->has('Wheel_base'))
											  <span class="text-danger">{{ $errors->first('Wheel_base') }}</span>
											@endif
                                        </div>
                                   </div>
                                   <div class="col-md-3">
                                        <div class="form-group">
                                           <label>Overall Length (mm)<span class="login-danger">*</span></label>
                                           <input type="text" name="Overall_Length" class="form-control" value="{{old('Overall_Length')}}">
										   @if($errors->has('Overall_Length'))
											  <span class="text-danger">{{ $errors->first('Overall_Length') }}</span>
											@endif
                                        </div>
                                   </div>
                                    <div class="col-md-3">
                                        <div class="form-group">
                                           <label>Overall Height (mm)<span class="login-danger">*</span></label>
                                           <input type="text" name="Overall_Height" class="form-control" value="{{old('Overall_Height')}}">
										   @if($errors->has('Overall_Height'))
											  <span class="text-danger">{{ $errors->first('Overall_Height') }}</span>
											@endif
                                        </div>
                                   </div>
                                   <div class="col-md-3">
                                        <div class="form-group">
                                           <label>Overall Width (mm)<span class="login-danger">*</span></label>
                                           <input type="text" name="Overall_Width" class="form-control" value="{{old('Overall_Width')}}">
										   @if($errors->has('Overall_Width'))
											  <span class="text-danger">{{ $errors->first('Overall_Width') }}</span>
											@endif
                                        </div>
                                   </div>
                                    <div class="col-md-3">
                                        <div class="form-group">
                                           <label>Ground Clearance (mm)<span class="login-danger">*</span></label>
                                           <input type="text" name="Ground_clearance" class="form-control" value="{{old('Ground_clearance')}}">
										   @if($errors->has('Ground_clearance'))
											  <span class="text-danger">{{ $errors->first('Ground_clearance') }}</span>
											@endif
                                        </div>
                                   </div>
                                   <div class="col-md-3">
                                        <div class="form-group">
                                           <label>Max. Permissible GVW<span class="login-danger">*</span></label>
                                           <input type="text" name="Max_Permissible_GVW" class="form-control" value="{{old('Max_Permissible_GVW')}}">
                                            
										    @if($errors->has('Max_Permissible_GVW'))
											  <span class="text-danger">{{ $errors->first('Max_Permissible_GVW') }}</span>
											@endif
                                        </div>
                                   </div>
                                    <div class="col-md-3">
                                        <div class="form-group">
                                           <label>Fuel Tank Capacity<span class="login-danger">*</span></label>
                                           <input type="text" name="Fuel_tank_Capacity" class="form-control" value="{{old('Fuel_tank_Capacity')}}">
										   @if($errors->has('Fuel_tank_Capacity'))
											  <span class="text-danger">{{ $errors->first('Fuel_tank_Capacity') }}</span>
											@endif
                                        </div>
                                   </div>
                                   <div class="col-md-3">
                                        <div class="form-group">
                                           <label>Steering Type<span class="login-danger">*</span></label>
                                           <input type="text" name="Steering_type" class="form-control" value="{{old('Steering_type')}}">
										   @if($errors->has('Steering_type'))
											  <span class="text-danger">{{ $errors->first('Steering_type') }}</span>
											@endif
                                        </div>
                                   </div>
                                    <div class="col-md-3">
                                        <div class="form-group">
                                           <label>Suspension Type  Front<span class="login-danger">*</span></label>
                                           <input type="text" name="Suspension_Type_Front" class="form-control" value="{{old('Suspension_Type_Front')}}">
										   @if($errors->has('Suspension_Type_Front'))
											  <span class="text-danger">{{ $errors->first('Suspension_Type_Front') }}</span>
											@endif
                                        </div>
                                   </div>
                                   <div class="col-md-3">
                                        <div class="form-group">
                                           <label>Suspension Type  Rear<span class="login-danger">*</span></label>
                                           <input type="text" name="Suspension_Type_Rear" class="form-control" value="{{old('Suspension_Type_Rear')}}">
										   @if($errors->has('Suspension_Type_Rear'))
											  <span class="text-danger">{{ $errors->first('Suspension_Type_Rear') }}</span>
											@endif
                                        </div>
                                   </div>
                                    <div class="col-md-3">
                                        <div class="form-group">
                                           <label>Wheels<span class="login-danger">*</span></label>
                                           <input type="text" name="Wheels" class="form-control" value="{{old('Wheels')}}">
										   @if($errors->has('Wheels'))
											  <span class="text-danger">{{ $errors->first('Wheels') }}</span>
											@endif
                                        </div>
                                   </div>
                                   <div class="col-md-3">
                                        <div class="form-group">
                                           <label>No. of Tyres<span class="login-danger">*</span></label>
                                           <!--<input type="text" name="No_of_tyres" class="form-control" value="{{old('No_of_tyres')}}">-->
                                           <select class="form-control" name="No_of_tyres">
                                               <option>Select</option>
                                               @foreach ($TyresCount as $key => $value)
                                               
                                               <option value="{{$value->tyres_type}}">{{$value->tyres_type}}</option>
                                                @endforeach 
                                           </select>
										   @if($errors->has('No_of_tyres'))
											  <span class="text-danger">{{ $errors->first('No_of_tyres') }}</span>
											@endif
                                        </div>
                                   </div>
                                    <div class="col-md-3">
                                        <div class="form-group">
                                           <label>Battery<span class="login-danger">*</span></label>
                                           <input type="text" name="Battery" class="form-control" value="{{old('Battery')}}">
										   @if($errors->has('Battery'))
											  <span class="text-danger">{{ $errors->first('Battery') }}</span>
											@endif
                                        </div>
                                   </div>
                                   <div class="col-md-3">
                                        <div class="form-group">
                                           <label>Brakes Type<span class="login-danger">*</span></label>
                                           <input type="text" name="Brakes_type" class="form-control" value="{{old('Brakes_type')}}">
										   @if($errors->has('Brakes_type'))
											  <span class="text-danger">{{ $errors->first('Brakes_type') }}</span>
											@endif
                                        </div>
                                   </div>
                                    <div class="col-md-3">
                                        <div class="form-group">
                                           <label>Parking Brake<span class="login-danger">*</span></label>
                                           <input type="text" name="Parking_brake" class="form-control" value="{{old('Parking_brake')}}">
										   @if($errors->has('Parking_brake'))
											  <span class="text-danger">{{ $errors->first('Parking_brake') }}</span>
											@endif
                                        </div>
                                   </div>
                                   <div class="col-md-3">
                                        <div class="form-group">
                                           <label>Auxiliary Braking System<span class="login-danger">*</span> </label>
                                           <input type="text" name="Auxiliary_Braking_System" class="form-control" value="{{old('Auxiliary_Braking_System')}}">
										   @if($errors->has('Auxiliary_Braking_System'))
											  <span class="text-danger">{{ $errors->first('Auxiliary_Braking_System') }}</span>
											@endif
                                        </div>
                                   </div>
                                    <div class="col-md-3">
                                        <div class="form-group">
                                           <label>Frame Type<span class="login-danger">*</span></label>
                                           <input type="text" name="Frame_type" class="form-control" value="{{old('Frame_type')}}">
										   @if($errors->has('Frame_type'))
											  <span class="text-danger">{{ $errors->first('Frame_type') }}</span>
											@endif
                                        </div>
                                   </div>
                                   <div class="col-md-3">
                                        <div class="form-group">
                                           <label>Diesel Exhaust Fluid (DEF)<span class="login-danger">*</span></label>
                                           <input type="text" name="Diesel_Exhaust_Fluid" class="form-control" value="{{old('Diesel_Exhaust_Fluid')}}">
										   @if($errors->has('Diesel_Exhaust_Fluid'))
											  <span class="text-danger">{{ $errors->first('Diesel_Exhaust_Fluid') }}</span>
											@endif
                                        </div>
                                   </div>
                                    <div class="col-md-3">
                                        <div class="form-group">
                                           <label>Front Axle Type<span class="login-danger">*</span></label>
                                           <input type="text" name="Front_axle_Type" class="form-control" value="{{old('Front_axle_Type')}}">
										   @if($errors->has('Front_axle_Type'))
											  <span class="text-danger">{{ $errors->first('Front_axle_Type') }}</span>
											@endif
                                        </div>
                                   </div>
                                   <div class="col-md-3">
                                        <div class="form-group">
                                           <label>Rear Axle Model<span class="login-danger">*</span></label>
                                           <input type="text" name="Rear_axle_Model" class="form-control" value="{{old('Rear_axle_Model')}}">
										   @if($errors->has('Rear_axle_Model'))
											  <span class="text-danger">{{ $errors->first('Rear_axle_Model') }}</span>
											@endif
                                        </div>
                                   </div>
                                    <div class="col-md-3">
                                        <div class="form-group">
                                           <label>Rear Axle Ratio<span class="login-danger">*</span></label>
                                           <input type="text" name="Rear_axle_Ratio" class="form-control" value="{{old('Rear_axle_Ratio')}}">
										   @if($errors->has('Rear_axle_Ratio'))
											  <span class="text-danger">{{ $errors->first('Rear_axle_Ratio') }}</span>
											@endif
                                        </div>
                                   </div>
                                   <div class="col-md-3">
                                        <div class="form-group">
                                           <label>Cabin Type<span class="login-danger">*</span></label>
                                           <input type="text" name="Cabin_type" class="form-control" value="{{old('Cabin_type')}}">
										   @if($errors->has('Cabin_type'))
											  <span class="text-danger">{{ $errors->first('Cabin_type') }}</span>
											@endif
                                        </div>
                                   </div>
                                    <div class="col-md-3">
                                        <div class="form-group">
                                           <label>Standard Features<span class="login-danger">*</span></label>
                                           <input type="text" name="Standard_features" class="form-control" value="{{old('Standard_features')}}">
										   @if($errors->has('Standard_features'))
											  <span class="text-danger">{{ $errors->first('Standard_features') }}</span>
											@endif
                                        </div>
                                   </div>
                                   <div class="col-md-3">
                                        <div class="form-group">
                                           <label>Maximum Gradebility<span class="login-danger">*</span></label>
                                           <input type="text" name="Maximum_gradebility" class="form-control" value="{{old('Maximum_gradebility')}}">
										   @if($errors->has('Maximum_gradebility'))
											  <span class="text-danger">{{ $errors->first('Maximum_gradebility') }}</span>
											@endif
                                        </div>
                                   </div>
                                   
                                   
                                    <div class="col-md-3">
                                        <div class="form-group">
                                           <label>Price Range<span class="login-danger">*</span></label>
                                           <input type="text" name="Price_Range" class="form-control" value="{{old('Price_Range')}}">
										   @if($errors->has('Price_Range'))
											  <span class="text-danger">{{ $errors->first('Price_Range') }}</span>
											@endif
                                        </div>
                                   </div>
                                   <div class="col-md-3">
                                        <div class="form-group">
                                           <label>Max Price<span class="login-danger">*</span></label>
                                           <input type="text" name="max_price" class="form-control" value="{{old('max_price')}}">
										   @if($errors->has('max_price'))
											  <span class="text-danger">{{ $errors->first('max_price') }}</span>
											@endif
                                        </div>
                                   </div>
                                   <div class="col-md-3">
                                        <div class="form-group">
                                           <label>Fuel Type<span class="login-danger">*</span></label>
                                          <select class="form-control" name="fule_type">
                                               <option>select</option>
                                               @foreach ($Fueltype as $key => $value)
                                                
                                                 <option value="{{$value->fuel_type_name}}">{{$value->fuel_type_name}}</option>
                                                @endforeach 
                                                
                                            </select>
										   @if($errors->has('fule_type'))
											  <span class="text-danger">{{ $errors->first('fule_type') }}</span>
											@endif
                                        </div>
                                   </div>
                                   <div class="col-md-3">
                                        <div class="form-group">
                                           <label>Select GVW<span class="login-danger">*</span></label>
                                           <!--<input type="text" name="Gvm" class="form-control" value="{{old('Gvm')}}">-->
                                           <select class="form-control" name="Gvm">
                                               <option>Select</option>
                                               @foreach ($Gvm as $key => $value)
                                                  <option value="{{$value->gvm_name}}">{{$value->gvm_name}}</option>
                                                @endforeach 
                                           </select>
										   @if($errors->has('Gvm'))
											  <span class="text-danger">{{ $errors->first('Gvm') }}</span>
											@endif
                                        </div>
                                   </div>
                                    <div class="col-md-3">
                                        <div class="form-group">
                                         <label>Vehicle Application<span class="login-danger">*</span> </label>
                                         <select class="form-control" name="add_application[]" multiple>
                                             
                                            @foreach ($VehicleApplication as $key => $value)
                                                  <option value="{{$value->vehicle_application_name}}">{{$value->vehicle_application_name}}</option>
                                                @endforeach 
                                            
                                        </select>
                                    </div>
                                   </div>
                                    <div class="col-md-3">
                                        <div class="form-group">
                                           <label>Featured Image<span class="login-danger">*</span> <small>(Size:650 X 373 px)</small> </label>
                                           <input type="file" name="images" class="form-control">
										   @if($errors->has('images'))
											  <span class="text-danger">{{ $errors->first('images') }}</span>
											@endif
                                        </div>
                                   </div>
                                   <div class="col-md-6">
                                        <div class="form-group">
                                           <label>Product Gallery<span class="login-danger">*</span> <small>(Size:650 X 373 px)</small></label>
                                           <input type="file" name="multi_image[]" id="multi_image" class="form-control" multiple>
										    @if($errors->has('multi_image'))
											  <span class="text-danger">{{ $errors->first('multi_image') }}</span>
											@endif
                                        </div>
                                   </div>
                                   <div class="col-md-3">
                                        <div class="form-group">
                                           <label>Truck Brochure<span class="login-danger">*</span> <small>(Only Pdf)</small> </label>
                                           <input type="file" name="brochure_pdf" class="form-control">
										   @if($errors->has('brochure_pdf'))
											  <span class="text-danger">{{ $errors->first('brochure_pdf') }}</span>
											@endif
                                        </div>
                                   </div>
                                    <div class="col-md-6">
                                        <div class="form-group">
                                           <label>Description<span class="login-danger">*</span></label>
                                           <textarea rows="5" cols="5" name="Description" class="form-control" placeholder="Enter message"></textarea>
										   @if($errors->has('Description'))
											  <span class="text-danger">{{ $errors->first('Description') }}</span>
											@endif
                                        </div>
                                   </div>
                                  
                                    <div class="text-start">
                                    <button type="submit" class="btn btn-primary">Submit</button>
                                    </div>
                            </form>
                        </div>
                    </div>
                </div>
                
        </div>
        
        <div class="row">
                <div class="col-md-12">
                    <div class="card">
                        <div class="card-header">
                            <h5 class="card-title">Upload Excel Sheet</h5>
                        </div>
                        <div class="card-body">
                           <form action="{{url('admin/import')}}" method="POST" enctype="multipart/form-data">
							 {{ csrf_field() }}
                                <div class="row">
                                    <div class="col-md-12">
                                        <div class="col-md-12">
                                            <div class="form-group">
                                               <label>Excel<span class="login-danger">*</span></label>
                                               <input type="file" name="file" class="form-control">
    										   @if($errors->has('excel'))
    											  <span class="text-danger">{{ $errors->first('excel') }}</span>
    											@endif
                                            </div>
                                       </div>
                                   </div>
                                    <div class="text-start">
                                    <button type="submit" class="btn btn-primary">Submit</button>
                                    </div>
                            </form>
                        </div>
                    </div>
                </div>
                
        </div>
        
        <div class="row">
                <div class="col-md-12">
                    <div class="card">
                        <div class="card-header">
                            <h5 class="card-title">Upload Bulk Image</h5>
                        </div>
                        <div class="card-body">
                           <form action="{{url('admin/importimage')}}" method="POST" enctype="multipart/form-data">
							 {{ csrf_field() }}
                                <div class="row">
                                    <div class="col-md-12">
                                        <div class="col-md-12">
                                            <div class="form-group">
                                               <label>Image(Upload .zip file)<span class="login-danger">*</span></label>
                                               <input type="file" name="zip_file" id="zip_file" accept=".zip" required class="form-control">
    										   @if($errors->has('excel'))
    											  <span class="text-danger">{{ $errors->first('excel') }}</span>
    											@endif
                                            </div>
                                       </div>
                                   </div>
                                    <div class="text-start">
                                    <button type="submit" class="btn btn-primary">Submit</button>
                                    </div>
                            </form>
                        </div>
                    </div>
                </div>
                
        </div>
        
        
</div>
        
@include('Admin.layouts.footer')
