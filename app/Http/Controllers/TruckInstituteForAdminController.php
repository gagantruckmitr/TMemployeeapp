<?php

namespace App\Http\Controllers;
use Illuminate\Support\Facades\Session;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Hash; 
use App\Models\User as TruckInstituteForAdmin;
use App\Models\User;
use App\Models\Job;
use App\Models\Vehicletype;
use App\Models\State;
use DB;
class TruckInstituteForAdminController extends Controller
{
    
    public function index()
    {
         if(empty(Session::get('role')=='admin')){
		return redirect('admin');
	  }
	  
        $institutes = TruckInstituteForAdmin::where('role', 'institute')->get();
        //dd($institutes);
        return view('Admin.institute.view', compact('institutes'));
    }

    
   public function edit(Request $request, $id)
    {
        if (empty(Session::get('role') == 'admin')) {
            return redirect('admin');
        }
    
        $list = TruckInstituteForAdmin::findOrFail($id);
        $states = State::all();
        $selectedState = $list->states;
    
        return view('Admin.institute.edit', compact('list', 'selectedState', 'states'));
    }

    
    public function update(Request $request)
    {
         if(empty(Session::get('role')=='admin')){
		return redirect('admin');
	  }
	  
        // Validate each field (modify validation rules as needed)
        $this->validate($request, [
            'images' => 'required',
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
        $id = $request->input('id');
        $institute = TruckInstituteForAdmin::find($id);
        
        if ($request->hasFile('images')) {
            $oldImagePath = public_path($institute->images);
        	if (file_exists($oldImagePath) && $institute->images) {
                unlink($oldImagePath);
            }
        	$image = $request->file('images');
            $imageName = time() . '.' . $image->getClientOriginalExtension();
            $image->move(public_path('images'), $imageName);
        	$institute->images = 'images/' . $imageName;
    	}
    	
        $institute->name = $request->input('name');
        $institute->mobile = $request->input('mobile');
        $institute->email = $request->input('email');
        $institute->address = $request->input('address');
        $institute->city = $request->input('city');
        $institute->states = $request->input('states');
        $institute->Training_Institute_Name = $request->input('Training_Institute_Name');
        $institute->Number_of_Seats_Available = $request->input('Number_of_Seats_Available');
        $institute->Monthly_Turnout = $request->input('Monthly_Turnout');
        $institute->Language_of_Training = $request->input('Language_of_Training');
        $institute->Placement_Candidates = $request->input('Placement_Candidates');
        $institute->Pay_Scale = $request->input('Pay_Scale');
        
        $institute->update();
    	
    
        return redirect()->back()->with('success', 'Institute updated successfully.');
    }

    
    public function destroy($id)
    {
         if(empty(Session::get('role')=='admin')){
		return redirect('admin');
	  }
	  
        $institute = TruckInstituteForAdmin::findOrFail($id);
    
        $institute->status = 0;
        $institute->save();
    
        return redirect()->back()->with('success', 'Institute deactivated successfully.');
    }
    
    public function institute_Driver(Request $request,$sub_id)
    {
       if(empty(Session::get('role')=='admin')){
		    return redirect('admin');
	   }
	    
       $id = $sub_id;
        
       $driver = User::where('sub_id', $id)->where('role', '=', 'driver')->get();
        
       return view('Admin/institute/driver/view', compact('driver'));   
    }
    
 public function transporter(Request $request)
{
    if (empty(Session::get('role') == 'admin')) {
        return redirect('admin');
    }


	 
	    $query = DB::table('users')
    ->leftJoin('states', function($join) {
        $join->on(DB::raw('CAST(users.states AS UNSIGNED)'), '=', 'states.id');
    })
    ->leftJoin('payments', function ($join) {
        $join->on('users.id', '=', 'payments.user_id')
             ->where('payments.payment_status', '=', 'captured'); // only captured payments
    })
    ->where('users.role', 'transporter')
    ->select(
        'users.*',
        'states.name as state_name',
        DB::raw('CASE WHEN payments.id IS NOT NULL THEN 1 ELSE 0 END as has_payment')
    )
    ->orderBy('users.created_at', 'desc');

    // Filter by State (filter based on ID in `users.states`)
    if ($request->filled('state')) {
        $query->where('users.states', $request->state);
    }

    // Filter by Status
    if ($request->filled('status')) {
        if ($request->status == 'active') {
            $query->where('users.status', '1');
        } elseif ($request->status == 'inactive') {
            $query->where('users.status', '0');
        }
    }

    // Filter by Date Range (created_at)
    if ($request->filled('from_date') && $request->filled('to_date')) {
        $from = date('Y-m-d 00:00:00', strtotime($request->from_date));
        $to   = date('Y-m-d 23:59:59', strtotime($request->to_date));
        $query->whereBetween('users.created_at', [$from, $to]);
    } elseif ($request->filled('from_date')) {
        $from = date('Y-m-d 00:00:00', strtotime($request->from_date));
        $query->where('users.created_at', '>=', $from);
    } elseif ($request->filled('to_date')) {
        $to = date('Y-m-d 23:59:59', strtotime($request->to_date));
        $query->where('users.created_at', '<=', $to);
    }
	 
	        // ✅ Payment Status Filter
    if ($request->filled('payment_status')) {
        if ($request->payment_status == 'captured') {
            $query->whereNotNull('payments.id'); // Received
        } elseif ($request->payment_status == 'not_received') {
            $query->whereNull('payments.id');   // Not Received
        }
    }

    $transporter = $query->orderBy('users.created_at', 'desc')->get();

    // Optional: fetch states from DB (dynamic dropdown)
    $states = DB::table('states')->select('id', 'name')->get();

    return view('Admin/transporter/transporter', compact('transporter', 'states'));
}
   
	
 public function subscribed_transporter_list(Request $request)
{
    if (empty(Session::get('role') == 'admin')) {
        return redirect('admin');
    }

	    $query = DB::table('users')->leftJoin('states', function($join) {
        $join->on(DB::raw('CAST(users.states AS UNSIGNED)'), '=', 'states.id');
    })
    ->join('payments', function ($join) {
        $join->on('users.id', '=', 'payments.user_id')
             ->where('payments.payment_status', '=', 'captured');
    })
    ->where('users.role', 'transporter')
    ->select(
        'users.*',
        'states.name as state_name',
        DB::raw('1 as has_payment'),
        DB::raw('payments.updated_at as subscription_date')
    )
    ->orderBy('users.created_at', 'desc');

    // Filter by State (filter based on ID in `users.states`)
    if ($request->filled('state')) {
        $query->where('users.states', $request->state);
    }

    // Filter by Status
    if ($request->filled('status')) {
        if ($request->status == 'active') {
            $query->where('users.status', '1');
        } elseif ($request->status == 'inactive') {
            $query->where('users.status', '0');
        }
    }

    // Filter by Date Range (created_at)
    if ($request->filled('from_date') && $request->filled('to_date')) {
        $from = date('Y-m-d 00:00:00', strtotime($request->from_date));
        $to   = date('Y-m-d 23:59:59', strtotime($request->to_date));
        $query->whereBetween('users.created_at', [$from, $to]);
    } elseif ($request->filled('from_date')) {
        $from = date('Y-m-d 00:00:00', strtotime($request->from_date));
        $query->where('users.created_at', '>=', $from);
    } elseif ($request->filled('to_date')) {
        $to = date('Y-m-d 23:59:59', strtotime($request->to_date));
        $query->where('users.created_at', '<=', $to);
    }

    $transporter = $query->orderBy('users.created_at', 'desc')->get();

    // Optional: fetch states from DB (dynamic dropdown)
    $states = DB::table('states')->select('id', 'name')->get();

    return view('Admin/transporter/subscribed_transporter_list', compact('transporter', 'states'));
}
   
	
     public function edit_transporter(Request $request,$id)
    {
       if(empty(Session::get('role')=='admin')){
		    return redirect('admin');
	   }
        
        
       $user = User::where('role', '=', 'transporter')->where('id', $id)->first();
         $Vehicletype = Vehicletype::all();
	     $states = State::all();
	     $selectedState = $user->states;
       return view('Admin/transporter/edit_transporter', compact('user','Vehicletype','selectedState','states'));   
    }
    
    public function update_transporter(Request $request,$id)
    {
	  if(empty(Session::get('role')=='admin')){
		    return redirect('admin');
	   }
	  // echo"kjndg"; die;
  
    $this->validate($request, [
        'name' => 'required',
        'mobile' => 'required',
        'Transport_Name' => 'required',
        'Registered_ID' => 'required',
        'PAN_Number' => 'required',
        'GST_Number' => 'required',
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
    $student->Transport_Name = $request->input('Transport_Name');
    $student->Year_of_Establishment = $request->input('Year_of_Establishment');
    $student->Registered_ID = $request->input('Registered_ID');
    $student->PAN_Number = $request->input('PAN_Number');
    $student->GST_Number = $request->input('GST_Number');
    $student->Fleet_Size = $request->input('Fleet_Size');
    $student->Operational_Segment = $request->input('Operational_Segment');
    $student->Average_KM = $request->input('Average_KM');
    $student->Referral_Code = $request->input('Referral_Code');
    
    if ($request->hasFile('PAN_Image')) {
    $oldImagePath = public_path($student->PAN_Image);
	if (file_exists($oldImagePath) && $student->PAN_Image) {
        unlink($oldImagePath);
    }
	$image = $request->file('PAN_Image');
    $imageName = time() . '.' . $image->getClientOriginalExtension();
    $image->move(public_path('images'), $imageName);
	$student->PAN_Image = 'images/' . $imageName;
	}
	
	if ($request->hasFile('GST_Certificate')) {
    $oldImagePath = public_path($student->GST_Certificate);
	if (file_exists($oldImagePath) && $student->GST_Certificate) {
        unlink($oldImagePath);
    }
	$image = $request->file('GST_Certificate');
    $imageName = time() . '.' . $image->getClientOriginalExtension();
    $image->move(public_path('images'), $imageName);
	$student->GST_Certificate = 'images/' . $imageName;
	}
    $student->update();
	Session::flash('success', 'Profile Update successfully!');
	return redirect()->back();
    }
    
    
    function status_transporter(Request $request,$id){
         if(empty(Session::get('role')=='admin')){
		    return redirect('admin');
	   }
	$product = DB::table('users')
				->select('status')
				->where('id','=',$id)
				->first();
	if($product->status == '1'){
		$status = '0';
	}else{
		$status = '1';
	}
	$values = array('status' => $status );
	DB::table('users')->where('id',$id)->update($values);
	return redirect('admin/transporter');
    }
    
    public function delete_transporter(Request $request, $id){
       if(empty(Session::get('role')=='admin')){
		    return redirect('admin');
	   }  
        $driver = User::findOrFail($id);
        $driver->delete();
        Session::flash('success', 'Record deleted successfully!');
        return redirect('admin/transporter');
    }
    
    public function transporter_job(Request $request,$id)
    {
       if(empty(Session::get('role')=='admin')){
		    return redirect('admin');
	   }
      
       $transporter_job = DB::table('users')
          ->join('jobs', 'users.id', '=', 'jobs.transporter_id') 
         ->select('users.*', 'jobs.*', 'jobs.id as id')
         ->where('users.id',$id)
          ->get();
          
       return view('Admin/transporter/transporter_job',compact('transporter_job'));   
    }
    
    public function delete_transporter_job(Request $request, $id){
       if(empty(Session::get('role')=='admin')){
		    return redirect('admin');
	   }  
        $driver = Job::findOrFail($id);
        $driver->delete();
        Session::flash('success', 'Job Record deleted successfully!');
        return redirect()->back();
    }
    
    public function view_apply_job_driver(Request $request, $tid, $jid){
        if(empty(Session::get('role')=='admin')){
		    return redirect('admin');
	   }
    	
    	$transport_id = $tid;
        $job = DB::table('users')
        ->join('applyjobs', 'applyjobs.driver_id', '=', 'users.id')
        ->join('jobs', 'jobs.id', '=', 'applyjobs.job_id')
        ->where('applyjobs.contractor_id', $transport_id)
        ->where('applyjobs.job_id', $jid)
        ->select('users.*', 'jobs.*', 'applyjobs.*')
        ->get();
        
        return view('Admin/transporter/appliedjob',compact('job'));  
    }
    
    
}