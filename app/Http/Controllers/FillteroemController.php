<?php
namespace App\Http\Controllers;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Session;
use Illuminate\Support\Str;   
use Illuminate\Support\Facades\File;  
use DB;
use App\Models\Fueltype;
use App\Models\Budget;  
use App\Models\VehicleApplication;
use App\Models\Gvm;
use App\Models\TyresCount;

class FillteroemController extends Controller
{
    
    public function budget(Request $request)
    {
     if (Session::get('role') != 'admin') {
			return redirect('admin');
		}
	
	     $Budget = Budget::all();
	     
	 return view('Admin/fillter/budget',compact('Budget'));	
	}
	
	public function add_budget(Request $request){
	    
	 if (Session::get('role') != 'admin') {
			return redirect('admin');
		}
		 $this->validate($request, [
        'budget_name' => 'required',
      ]);
      
     $student = new Budget;
     $student->budget_name = $request->input('budget_name');
     $student->save();
	 Session::flash('success', 'budget added successfully!');
	return redirect('admin/budget');    
	}
	
   public function delete_budget(Request $request,$id)
	{
	  if(Session::get('role') != 'admin') {
		 return redirect('admin');
	   }
	   
		Budget::find($id)->delete();
        Session::flash('success', 'Record Delete successful!');
	return redirect('admin/budget');
	}
	
	public function fuel_type(Request $request)
    {
     if (Session::get('role') != 'admin') {
			return redirect('admin');
		}
	
	     $Fueltype = Fueltype::all();
	     
	 return view('Admin/fillter/fueltype',compact('Fueltype'));	
	}
	
	public function add_fuel_type(Request $request){
	    
	 if (Session::get('role') != 'admin') {
			return redirect('admin');
		}
		 $this->validate($request, [
        'fuel_type_name' => 'required',
      ]);
      
     $student = new Fueltype;
     $student->fuel_type_name = $request->input('fuel_type_name');
     $student->save();
	 Session::flash('success', 'Fuel type added successfully!');
	return redirect('admin/fuel-type');    
	}
	
   public function delete_fuel_type(Request $request,$id)
	{
	  if(Session::get('role') != 'admin') {
		 return redirect('admin');
	   }	  
		Fueltype::find($id)->delete();
        Session::flash('success', 'Record Delete successful!');
	return redirect('admin/fuel-type');
	}
	
	public function vehicle_application(Request $request)
    {
     if (Session::get('role') != 'admin') {
			return redirect('admin');
		}
	
	     $VehicleApplication = VehicleApplication::all();
	     
	 return view('Admin/fillter/vehicle_application',compact('VehicleApplication'));	
	}
	
	public function add_vehicle_application(Request $request){
	    
	 if (Session::get('role') != 'admin') {
			return redirect('admin');
		}
		 $this->validate($request, [
        'vehicle_application_name' => 'required',
      ]);
      
     $student = new VehicleApplication;
     $student->vehicle_application_name = $request->input('vehicle_application_name');
     $student->save();
	 Session::flash('success', 'Vehicle Application added successfully!');
	return redirect('admin/vehicle-application');    
	}
	
   public function delete_vehicle_application(Request $request,$id)
	{
	  if(Session::get('role') != 'admin') {
		 return redirect('admin');
	   }	  
		VehicleApplication::find($id)->delete();
        Session::flash('success', 'Record Delete successful!');
	return redirect('admin/vehicle-application');
	}
    
   public function gvm(Request $request)
    {
     if (Session::get('role') != 'admin') {
			return redirect('admin');
		}
	
	     $Gvm = Gvm::all();
	     
	 return view('Admin/fillter/Gvm',compact('Gvm'));	
	}
	
	public function add_gvm(Request $request){
	    
	 if (Session::get('role') != 'admin') {
			return redirect('admin');
		}
		 $this->validate($request, [
        'gvm_name' => 'required',
      ]);
      
     $student = new Gvm;
     $student->gvm_name = $request->input('gvm_name');
     $student->save();
	 Session::flash('success', 'GVM added successfully!');
	return redirect('admin/gvm');    
	}
	
   public function delete_gvm(Request $request,$id)
	{
	  if(Session::get('role') != 'admin') {
		 return redirect('admin');
	   }	  
		Gvm::find($id)->delete();
        Session::flash('success', 'Record Delete successful!');
	return redirect('admin/gvm');
	}
	
	public function tyres_count(Request $request)
    {
     if (Session::get('role') != 'admin') {
			return redirect('admin');
		}
	
	     $TyresCount = TyresCount::all();
	     
	 return view('Admin/fillter/tyrescount',compact('TyresCount'));	
	}
	
	public function add_tyres_count(Request $request){
	    
	 if (Session::get('role') != 'admin') {
			return redirect('admin');
		}
		 $this->validate($request, [
        'tyres_type' => 'required',
      ]);
      
     $student = new TyresCount;
     $student->tyres_type = $request->input('tyres_type');
     $student->save();
	 Session::flash('success', 'Tyres count added successfully!');
	return redirect('admin/tyres-count');    
	}
	
   public function delete_tyres_count(Request $request,$id)
	{
	  if(Session::get('role') != 'admin') {
		 return redirect('admin');
	   }	  
		TyresCount::find($id)->delete();
        Session::flash('success', 'Record Delete successful!');
	return redirect('admin/tyres-count');
	}
	
}