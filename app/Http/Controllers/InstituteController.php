<?php

namespace App\Http\Controllers;
use Illuminate\Support\Facades\Session;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Hash;  
use App\Models\User;
use App\Models\Vehicletype;
use App\Models\State;
use App\Imports\DriverImport;
use Maatwebsite\Excel\Facades\Excel;
use DB;
class InstituteController extends Controller
{	
	
    public function dashboard()
    {
	  if(empty(Session::get('role')=='institute')){
		return redirect('/');
	  }
	
	  $id = Session::get('id');
      $totaldriver = User::where('sub_id', $id)->where('role', '=', 'driver')->count();
      
       $user = User::where('id', $id)->first();
       
     return view('institute/dashboard',compact('totaldriver','user'));
    }
    
    public function update_status(Request $request, $id, $status){
        if($id){
            try{
                
                $user = User::where('id', $id)->update(['status' => $status]);;
                if($user){
                    echo "updated";
                }else{
                    echo "Not Updated";
                }
            } catch (\Exception $e){
                return response()->json(['message' => 'An error occurred while updating user status.', 'error' => $e->getMessage()], 500);
            }
        }
    }
    
    public function add_driver_excel(Request $request){
        if(empty(Session::get('role')=='institute')){
		return redirect('/');
	  }
        return view('institute/add_driver_excel'); 
    }
    
    
    public function importDriver(Request $request){
        if(empty(Session::get('role')=='institute')){
		return redirect('/');
	  }
        $request->validate([
            'file' => 'required|mimes:xlsx,csv,xls',
        ]);
        // DB::enableQueryLog();
        Excel::import(new DriverImport, $request->file('file'));
        // dd(DB::getQueryLog());
        return redirect()->back()->with('success', 'Data Imported Successfully');
    }
    
	public function importDriverImage(Request $request){
	    if(empty(Session::get('role')=='institute')){
		return redirect('/');
	  }
        $request->validate([
            'zip_file' => 'required|mimes:zip|max:2048',
        ]);

        // Store the uploaded file temporarily
        $file = $request->file('zip_file');
        $path = $file->storeAs('temp', $file->getClientOriginalName());

        // Define the extraction path
        $extractTo = public_path('images'); // Folder where the files will be extracted

        // Make sure the extraction directory exists
        if (!File::exists($extractTo)) {
            File::makeDirectory($extractTo, 0777, true);
        }

        // Extract the ZIP file
        $zip = new ZipArchive;
        $zipFilePath = storage_path('app/'.$path);

        if ($zip->open($zipFilePath) === TRUE) {
            $zip->extractTo($extractTo);
            $zip->close();

            // Optionally, delete the ZIP file after extraction
            File::delete($zipFilePath);

            return back()->with('success', 'File uploaded and extracted successfully!');
        } else {
            return back()->with('error', 'Failed to open ZIP file.');
        }
    }
    
    public function profile()
    {
	  if(empty(Session::get('role')=='institute')){
		return redirect('/');
	  }
	    $id = Session::get('id');
    
      $user = User::where('id', $id)->where('role', '=', 'institute')->first();
      $states = State::all();
	  $selectedState = $user->states;
     return view('institute/profile',compact('user','states','selectedState'));
    }
    public function profile_update(Request $request)
    {
	  if(empty(Session::get('role')=='institute')){
		return redirect('/');
	  }
	  
	$id = Session::get('id');
  
    $this->validate($request, [
        'name' => 'required',
        'mobile' => 'required',
        'email' => 'required',
        'address' => 'required',
        'city' => 'required',
        'states' => 'required',
        'Training_Institute_Name' => 'required',
        'Number_of_Seats_Available' => 'required',
        'Monthly_Turnout' => 'required',
        'Language_of_Training' => 'required',
        'Placement_Candidates' => 'required',
        'Pay_Scale' => 'required',
    ]);
    
    $student = User::find($id);
    
     if ($request->hasFile('images')) {
    $oldImagePath = public_path($student->images);
	if (file_exists($oldImagePath) && $student->images) {
        unlink($oldImagePath);
    }
	$image = $request->file('images');
    $imageName = time() . '.' . $image->getClientOriginalExtension();
    $image->move(public_path('images'), $imageName);
	$student->images = 'images/' . $imageName;
	}
	
    $student->name = $request->input('name');
    $student->mobile = $request->input('mobile');
    $student->email = $request->input('email');
    $student->address = $request->input('address');
    $student->city = $request->input('city');
    $student->states = $request->input('states');
    $student->Training_Institute_Name = $request->input('Training_Institute_Name');
    $student->Number_of_Seats_Available = $request->input('Number_of_Seats_Available');
    $student->Monthly_Turnout = $request->input('Monthly_Turnout');
    $student->Language_of_Training = $request->input('Language_of_Training');
    $student->Placement_Candidates = $request->input('Placement_Candidates');
    $student->Pay_Scale = $request->input('Pay_Scale');
    $student->update();
	Session::flash('success', 'Profile Update successfully!');
    return redirect('institute/profile');
    }
    
    public function add_driver()
    {
	  if(empty(Session::get('role')=='institute')){
		return redirect('/');
	  }
	  
	  $states = State::all();
	  $Vehicletype = Vehicletype::all();
     return view('institute/add_driver',compact('states','Vehicletype'));
    }
    
   public function driver_create(Request $request)
    {
       	
    $data = $request->validate([
        'name'     => 'required',
        'mobile'   => 'required|numeric|digits:10|unique:users,mobile',
        'password' => 'required|confirmed',
        'DOB'                  => 'required',
        'vehicle_type'         => 'required',
        'Type_of_License' => 'required|unique:users,Type_of_License',
        'Aadhar_Number' => 'required|unique:users,Aadhar_Number',
        'Aadhar_Photo'         => 'required',
        'Driving_License'      => 'required',
         ], [
        'Type_of_License.unique' => 'The Type of License is already in use.',
        'Aadhar_Number.unique' => 'The Aadhar Number is already registered.',
    ]);
    
    	$subId = Session::get('id');
    	$st = $request->input('states');
    	$state_code = '';
        $state_code = DB::select("select * from states where name='$st'");
        foreach ($state_code as $row) {
            $state_code = $row->codes; // Replace column_name with your actual column name
        }
        $student = new User;
		$student->role = 'driver';
		$student->unique_id=generate_nomenclature_id('TD', $state_code);
		$student->sub_id = $subId;
		$student->name = $request->input('name');
		$student->email = $request->input('email');
		$student->mobile = $request->input('mobile');
		$student->password = Hash::make($request->input('password'));
		$student->Father_Name = $request->input('Father_Name');
		$student->DOB = $request->input('DOB');
		$student->vehicle_type = $request->input('vehicle_type');
		$student->Sex = $request->input('Sex');
		$student->Marital_Status = $request->input('Marital_Status');
		$student->Highest_Education = $request->input('Highest_Education');
		$student->Driving_Experience = $request->input('Driving_Experience');
		$student->Type_of_License = $request->input('Type_of_License');
		$student->Expiry_date_of_License = $request->input('Expiry_date_of_License');
		$student->address = $request->input('address');
		$student->city = $request->input('city');
		$student->states = $request->input('states');
		$student->Preferred_Location = $request->input('Preferred_Location');
		$student->Current_Monthly_Income = $request->input('Current_Monthly_Income');
		$student->Expected_Monthly_Income = $request->input('Expected_Monthly_Income');
		$student->Aadhar_Number = $request->input('Aadhar_Number');
    if ($request->hasFile('images')) {
        $image = $request->file('images');
        $imageName = time() . '_image.' . $image->getClientOriginalExtension();
        $image->move(public_path('images'), $imageName);
        $student->images = 'images/' . $imageName;
    }

    if ($request->hasFile('Aadhar_Photo')) {
        $aadharPhoto = $request->file('Aadhar_Photo');
        $aadharPhotoName = time() . '_aadhar.' . $aadharPhoto->getClientOriginalExtension();
        $aadharPhoto->move(public_path('images'), $aadharPhotoName);
        $student->Aadhar_Photo = 'images/' . $aadharPhotoName;
    }

    if ($request->hasFile('Driving_License')) {
        $drivingLicense = $request->file('Driving_License');
        $licenseName = time() . '_license.' . $drivingLicense->getClientOriginalExtension();
        $drivingLicense->move(public_path('images'), $licenseName);
        $student->Driving_License = 'images/' . $licenseName;
    }
    $student->job_placement = $request->input('job_placement');
    $student->previous_employer = $request->input('previous_employer');
    $student->save();
    return redirect('institute/driver')->with('success', 'Driver Registration is Completed');
    }
	
    public function driver()
    {
	  if(empty(Session::get('role')=='institute')){
		return redirect('/');
	  }
	  
	  $id = Session::get('id');
	  
	  $user = User::where('sub_id', $id)->where('role', '=', 'driver')->get();
	  
     return view('institute/driver',compact('user'));
    }
    
    public function edit_driver(Request $request,$id)
	 {
		 if(empty(Session::get('role')=='institute')){
		return redirect('/');
	  }
		
	  $user = User::find($id);
	  $states = State::all();
	  $selectedState = $user->states; 
	return view('institute/edit_driver',compact('user','states','selectedState'));
	 }
	
	public function update_driver(Request $request,$id)
	 {
		if (Session::get('role') != 'institute') {
			return redirect('/');
		}
        $data = $request->validate([
        'name'     => 'required',
        'mobile'   => 'required|numeric|digits:10|unique:users,mobile',
        'password' => 'required|confirmed',
        'DOB'                  => 'required',
        'vehicle_type'         => 'required',
        'Type_of_License'      => 'required',
        'Aadhar_Number'        => 'required',
        'Aadhar_Photo'         => 'required',
        'Driving_License'      => 'required',
         ]);
    	
    	$subId = Session::get('id');
    
        $student = User::find($id);
		$student->role = 'driver';
		$student->sub_id = $subId;
		$student->name = $request->input('name');
		$student->email = $request->input('email');
		$student->mobile = $request->input('mobile');
		$student->Father_Name = $request->input('Father_Name');
		$student->DOB = $request->input('DOB');
		$student->vehicle_type = $request->input('vehicle_type');
		$student->Sex = $request->input('Sex');
		$student->Marital_Status = $request->input('Marital_Status');
		$student->Highest_Education = $request->input('Highest_Education');
		$student->Driving_Experience = $request->input('Driving_Experience');
		$student->Type_of_License = $request->input('Type_of_License');
		$student->Expiry_date_of_License = $request->input('Expiry_date_of_License');
		$student->address = $request->input('address');
		$student->city = $request->input('city');
		$student->states = $request->input('states');
		$student->Preferred_Location = $request->input('Preferred_Location');
		$student->Current_Monthly_Income = $request->input('Current_Monthly_Income');
		$student->Expected_Monthly_Income = $request->input('Expected_Monthly_Income');
		$student->Aadhar_Number = $request->input('Aadhar_Number');
		
        if ($request->hasFile('images')) {
        $oldImagePath = public_path($student->images);
    	if (file_exists($oldImagePath) && $student->images) {
            unlink($oldImagePath);
        }
    	$image = $request->file('images');
        $imageName = time() . '.' . $image->getClientOriginalExtension();
        $image->move(public_path('images'), $imageName);
    	$student->images = 'images/' . $imageName;
    	}
    	
    	if ($request->hasFile('Aadhar_Photo')) {
        $oldImagePath = public_path($student->Aadhar_Photo);
    	if (file_exists($oldImagePath) && $student->Aadhar_Photo) {
            unlink($oldImagePath);
        }
    	$image = $request->file('Aadhar_Photo');
        $imageName = time() . '.' . $image->getClientOriginalExtension();
        $image->move(public_path('images'), $imageName);
    	$student->Aadhar_Photo = 'images/' . $imageName;
    	}
    	
    	if ($request->hasFile('Driving_License')) {
        $oldImagePath = public_path($student->Driving_License);
    	if (file_exists($oldImagePath) && $student->Driving_License) {
            unlink($oldImagePath);
        }
    	$image = $request->file('Driving_License');
        $imageName = time() . '.' . $image->getClientOriginalExtension();
        $image->move(public_path('images'), $imageName);
    	$student->Driving_License = 'images/' . $imageName;
    	}
    	
        $student->update();
	    Session::flash('success', 'Driver Update successfully!');
       return redirect('institute/driver');
	  }
	
	 public function driver_delete(Request $request, $id)
        {
           if(Session::get('role') != 'institute') {
        		 return redirect('/');
        	   }	  
        		User::find($id)->delete();
                Session::flash('success', 'Record Delete successful!');
            return redirect('institute/driver');
    }
    
    public function institute_logouts(Request $request){
     if(empty(Session::get('role')=='institute')){
		return redirect('login');
	  }
		$request->session()->flush();
		$request->session()->flush('name');
		$request->session()->flush('role');
		
        return redirect('login');
    }
	
	
}
