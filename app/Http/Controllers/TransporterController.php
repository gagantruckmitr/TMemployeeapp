<?php

namespace App\Http\Controllers;
use Illuminate\Support\Facades\Session;
use Illuminate\Http\Request;
use App\Models\User;
use App\Models\Job;
use App\Models\State;
use App\Models\Vehicletype;
use DB;
use App\Mail\JobMail;
use App\Imports\DriverImport;
use Maatwebsite\Excel\Facades\Excel;
use Illuminate\Support\Facades\Mail;


class TransporterController extends Controller
{
    public function dashboard()
    {
        if (empty(Session::get("role") == "transporter")) {
            return redirect("/");
        }

        $id = Session::get("id");
        $totaljob = Job::where("transporter_id", $id)->count();

        $user = User::where("id", $id)->first();

        return view("transporter/dashboard", compact("totaljob", "user"));
    }

    //     public function trans_profile()
    //     {
    //      if(empty(Session::get('role')=='transporter')){
    // 		return redirect('/');
    // 	  }

    // 	   $id = Session::get('id');

    //     $user = User::where('id', $id)->where('role', '=', 'transporter')->first();
    //     //dd($user);
    //       $states = State::all();
    // 	  $selectedState = $user->states;
    //       return view('transporter/profile',compact('user','selectedState','states'));
    //     }

    public function trans_profile()
    {
        if (Session::get("role") !== "transporter") {
            return redirect("/");
        }

        $id = Session::get("id");
        $user = User::where("id", $id)
            ->where("role", "transporter")
            ->first();

        if (!$user) {
            return redirect("/")->with(
                "error",
                "User not found or unauthorized."
            );
        }
        if (!is_array($user->Operational_Segment)) {
            if (is_string($user->Operational_Segment)) {
                $user->Operational_Segment =
                    json_decode($user->Operational_Segment, true) ??
                    explode(",", $user->Operational_Segment);
            } else {
                $user->Operational_Segment = [];
            }
        }
        $states = State::all();
        $selectedState = $user->states;
        return view(
            "transporter/profile",
            compact("user", "selectedState", "states")
        );
    }

    public function add_driver_excel(Request $request)
    {
        if (empty(Session::get("role") == "transporter")) {
            return redirect("/");
        }
        return view("transporter/add_driver_excel");
    }

    public function importDriver(Request $request)
{
    try {
        $import = new DriverImport();
        Excel::import($import, $request->file('file'));

        // Fetch validation failures from Laravel Excel
        $validationErrors = [];

        if ($import->failures()->isNotEmpty()) {
            foreach ($import->failures() as $failure) {
                $row = intval($failure->row()); // Ensure row is an integer
                $errorMessage = implode(', ', $failure->errors());

                // Group errors by row
                if (!isset($validationErrors[$row])) {
                    $validationErrors[$row] = "Row $row: " . $errorMessage;
                } else {
                    $validationErrors[$row] .= ', ' . $errorMessage;
                }
            }
        }

        // Check for manually tracked duplicate errors
        if (session()->has('import_errors')) {
            foreach (session('import_errors') as $error) {
                $row = isset($error['row']) ? intval($error['row']) : 0; // Ensure row is an integer
                $errorMessage = $error['error'];

                if (!isset($validationErrors[$row])) {
                    $validationErrors[$row] = "Row $row: " . $errorMessage;
                } else {
                    $validationErrors[$row] .= ', ' . $errorMessage;
                }
            }
            session()->forget('import_errors'); // Clear errors after fetching
        }

        if (!empty($validationErrors)) {
            return back()->withErrors($validationErrors);
        }

        return back()->with('success', 'Drivers imported successfully!');
    } catch (ValidationException $e) {
        $validationErrors = [];

        foreach ($e->failures() as $failure) {
            $row = intval($failure->row()); // Convert row to integer
            $errorMessage = implode(', ', $failure->errors());

            if (!isset($validationErrors[$row])) {
                $validationErrors[$row] = "Row $row: " . $errorMessage;
            } else {
                $validationErrors[$row] .= ', ' . $errorMessage;
            }
        }

        return back()->withErrors($validationErrors);
    }
}


    public function profiles_update(Request $request)
    {
        if (empty(Session::get("role") == "transporter")) {
            return redirect("/");
        }

        $id = Session::get("id");

        $request->validate(
            [
                "name" => "required",
                "mobile" => "required",
                "Transport_Name" => "required",
                "Registered_ID" => "required",
                "PAN_Number" =>
                    "required|unique:users,PAN_Number," . $id . ",id",
                "GST_Number" =>
                    "required|unique:users,GST_Number," . $id . ",id",
            ],
            [
                "PAN_Number.unique" => "The PAN Number is already in use.",
                "GST_Number.unique" => "The GST Number is already registered.",
            ]
        );

        $student = User::find($id);

        if ($request->hasFile("images")) {
            $oldImagePath = public_path($student->images);
            if (file_exists($oldImagePath) && $student->images) {
                unlink($oldImagePath);
            }
            $image = $request->file("images");
            $imageName = time() . "." . $image->getClientOriginalExtension();
            $image->move(public_path("images"), $imageName);
            $student->images = "images/" . $imageName;
        }

        $student->name = $request->input("name");
        $student->mobile = $request->input("mobile");
        $student->email = $request->input("email");
        $student->address = $request->input("address");
        $student->city = $request->input("city");
        $student->states = $request->input("states");
        $student->Transport_Name = $request->input("Transport_Name");
        $student->Year_of_Establishment = $request->input(
            "Year_of_Establishment"
        );
        $student->Registered_ID = $request->input("Registered_ID");
        $student->PAN_Number = $request->input("PAN_Number");
        $student->GST_Number = $request->input("GST_Number");
        $student->Fleet_Size = $request->input("Fleet_Size");
        $student->Operational_Segment = json_encode(
            $request->input("Operational_Segment")
        );
        //$student->Operational_Segment = is_array($user->Operational_Segment)
        // ? $student->Operational_Segment
        //: json_decode($student->Operational_Segment, true);

        $student->Average_KM = $request->input("Average_KM");
        $student->Referral_Code = $request->input("Referral_Code");

        if ($request->hasFile("PAN_Image")) {
            $oldImagePath = public_path($student->PAN_Image);
            if (file_exists($oldImagePath) && $student->PAN_Image) {
                unlink($oldImagePath);
            }
            $image = $request->file("PAN_Image");
            $imageName = time() . "." . $image->getClientOriginalExtension();
            $image->move(public_path("images"), $imageName);
            $student->PAN_Image = "images/" . $imageName;
        }

        if ($request->hasFile("GST_Certificate")) {
            $oldImagePath = public_path($student->GST_Certificate);
            if (file_exists($oldImagePath) && $student->GST_Certificate) {
                unlink($oldImagePath);
            }
            $image = $request->file("GST_Certificate");
            $imageName = time() . "." . $image->getClientOriginalExtension();
            $image->move(public_path("images"), $imageName);
            $student->GST_Certificate = "images/" . $imageName;
        }
        $student->update();
        Session::flash("success", "Profile Update successfully!");
        return redirect("transporter/profile");
    }

    public function add_job()
    {
        if (empty(Session::get("role") == "transporter")) {
            return redirect("/");
        }

        $Vehicletype = Vehicletype::all();
        $states = State::all();
        return view("transporter/add_job", compact("Vehicletype", "states"));
    }

    // public function create_job(Request $request)
    // {
    //     if (empty(Session::get("role") == "transporter")) {
    //         return redirect("/");
    //     }

    //     $this->validate($request, [
    //         "job_title" => "required",
    //         "Required_Experience" => "required",
    //         "Salary_Range" => "required",
    //         "Type_of_License" => "required",
    //         "Preferred_Skills" => "required",
    //         "Application_Deadline" => "required",
    //         "Job_Management" => "required",
    //         "Job_Description" => "required",
    //     ]);

    //     $tr_Id = Session::get("id");

    //     $job = new Job();
    //     $job->transporter_id = $tr_Id;
    //     $job->job_title = $request->input("job_title");
    //     $job->vehicle_type = $request->input("vehicle_type");
    //     $job->job_location = $request->input("job_location");
    //     $job->Required_Experience = $request->input("Required_Experience");
    //     $job->Salary_Range = $request->input("Salary_Range");
    //     $job->Type_of_License = $request->input("Type_of_License");
    //     $job->Preferred_Skills = $request->input("Preferred_Skills");
    //     $job->Application_Deadline = $request->input("Application_Deadline");
    //     $job->Job_Management = $request->input("Job_Management");
    //     $job->Job_Description = $request->input("Job_Description");
    //     //$job->Job_Description = htmlspecialchars($request->input('Job_Description'), ENT_QUOTES, 'UTF-8');
    //     $job->save();
    //     $job->job_id = "TMJB" . str_pad($job->id, 5, "0", STR_PAD_LEFT);
    //     $job->save();
    //     Session::flash("success", "Job created successfully & You can edit wihtin 24 hrs only!");
    //     return redirect("transporter/job");
    // }

    public function create_job(Request $request)
    {
        // Check if the user is a transporter
        if (Session::get("role") !== "transporter") {
            return redirect("/");
        }

        // Validate form data
        $this->validate($request, [
            "job_title" => "required",
            "Required_Experience" => "required",
            "Salary_Range" => "required",
            "Type_of_License" => "required",
            "Preferred_Skills" => "required",
            "Application_Deadline" => "required",
            "Job_Management" => "required",
            "Job_Description" => "required",
        ]);

        $tr_Id = Session::get("id");
        $transporter_email = Session::get("email"); // Fetch transporter email from session

        // Create Job Entry
        $job = new Job();
        $job->transporter_id = $tr_Id;
        $job->job_title = $request->input("job_title");
        $job->vehicle_type = $request->input("vehicle_type");
        $job->job_location = $request->input("job_location");
        $job->Required_Experience = $request->input("Required_Experience");
        $job->Salary_Range = $request->input("Salary_Range");
        $job->Type_of_License = $request->input("Type_of_License");
        $job->Preferred_Skills = $request->input("Preferred_Skills");
        $job->Application_Deadline = $request->input("Application_Deadline");
        $job->Job_Management = $request->input("Job_Management");
        $job->Job_Description = $request->input("Job_Description");
        $job->save();

        // Generate Unique Job ID
        $job->job_id = "TMJB" . str_pad($job->id, 5, "0", STR_PAD_LEFT);
        $job->save();

        // Prepare Job Data for Email
        $jobData = [
            "transporter_name" => Session::get("name"),
            "job_title" => $job->job_title,
            "job_location" => $job->job_location,
            "vehicle_type" => $job->vehicle_type,
            "experience" => $job->Required_Experience,
            "salary_range" => $job->Salary_Range,
            "license_type" => $job->Type_of_License,
            "preferred_skills" => $job->Preferred_Skills,
            "application_deadline" => $job->Application_Deadline,
            "drivers_required" => $job->Job_Management,
            "job_description" => $job->Job_Description,
        ];

        // Send Job Posted Email
        Mail::to($transporter_email) // Send to transporter
            ->cc(["contact@truckmitr.com"]) // CC to additional recipient
            ->send(new JobMail($jobData));

        // Success message
        Session::flash(
            "success",
            "Job created successfully! You can edit it within 24 hours only."
        );
        return redirect("transporter/job");
    }
    function sendMail($to, $subject, $template)
    {
        // Headers

        $template = "
        <!DOCTYPE html>
        <html>
        <head>
            <title>Job Created</title>
        </head>
        <body>
            <h1>Thank You!</h1>
            <p>Thank you for creating this job. You can edit it within 24 hours of its creation.</p>
        </body>
        </html>
        ";
        // Send email
        if (mail($to, $subject, $template)) {
            return "Email sent successfully to $to";
        } else {
            return "Failed to send email to $to";
        }
    }

    public function job()
    {
        if (empty(Session::get("role") == "transporter")) {
            return redirect("/");
        }

        $id = Session::get("id");

        $job = Job::where("transporter_id", $id)
            ->orderBy("id", "desc")
            ->get();

        return view("transporter/job", compact("job"));
    }

    public function edit_job(Request $request, $id)
    {
        if (empty(Session::get("role") == "transporter")) {
            return redirect("/");
        }

        $job = Job::where("id", $id)->first();
        $Vehicletype = Vehicletype::all();
        $states = State::all();

        return view(
            "transporter/edit_job",
            compact("job", "Vehicletype", "states")
        );
    }

    public function job_update(Request $request, $id)
    {
        if (empty(Session::get("role") == "transporter")) {
            return redirect("/");
        }
        //echo "dsnsdkjgs"; die;
        $this->validate($request, [
            "job_title" => "required",
            "job_location" => "required",
            "Required_Experience" => "required",
            "Salary_Range" => "required",
            "Type_of_License" => "required",
            "Preferred_Skills" => "required",
            "Application_Deadline" => "required",
            "Job_Management" => "required",
            "Job_Description" => "required",
        ]);

        $student = Job::find($id);
        $student->job_title = $request->input("job_title");
        $student->vehicle_type = $request->input("vehicle_type");
        $student->job_location = $request->input("job_location");
        $student->Required_Experience = $request->input("Required_Experience");
        $student->Salary_Range = $request->input("Salary_Range");
        $student->Type_of_License = $request->input("Type_of_License");
        $student->Preferred_Skills = $request->input("Preferred_Skills");
        $student->Application_Deadline = $request->input(
            "Application_Deadline"
        );
        $student->Job_Management = $request->input("Job_Management");
        $student->Job_Description = $request->input("Job_Description");
        $student->update();
        Session::flash("success", "Job Update successfully!");
        return redirect("transporter/job");
    }

    public function job_delete(Request $request, $id)
    {
        if (Session::get("role") != "transporter") {
            return redirect("/");
        }
        Job::find($id)->delete();
        Session::flash("success", "Record Delete successful!");
        return redirect("transporter/job");
    }

    public function transporter_logouts(Request $request)
    {
        if (empty(Session::get("role") == "transporter")) {
            return redirect("login");
        }
        $request->session()->flush();
        $request->session()->flush("name");
        $request->session()->flush("role");

        return redirect("login");
    }

    public function appliedjob(Request $request)
    {
        if (empty(Session::get("role") == "transporter")) {
            return redirect("login");
        }
        $id = Session::get("id");

        $job = Job::where("transporter_id", $id)
            ->orderBy("id", "desc")
            ->get();

        return view("transporter/appliedjob", compact("job"));
    }

    public function getDriverApplied(Request $request, $job_id, $trans_id)
    {
        if (empty(Session::get("role") == "transporter")) {
            return redirect("login");
        }
        $id = Session::get("id");
        $job = DB::table("users")
            ->join("applyjobs", "applyjobs.driver_id", "=", "users.id")
            ->join("jobs", "jobs.id", "=", "applyjobs.job_id")
            ->where("applyjobs.contractor_id", $trans_id)
            ->where("applyjobs.job_id", $job_id)
            ->select("users.*", "users.id as uid", "jobs.*", "applyjobs.*")
            ->get();

        return view("transporter/applieddriver", compact("job"));
    }

    public function updateGetJobStatus(Request $request)
    {
        // Validate the incoming request
        $request->validate([
            "job_id" => "required|integer",
            "transportor_id" => "required|integer",
            "driver_id" => "required|integer",
            "status" => "required|string|in:Accepted,Rejected,Pending",
        ]);

        // Check if the combination of job_id, transportor_id, and driver_id already exists
        $existingJob = DB::table("get_job")
            ->where("job_id", $request->job_id)
            ->where("transportor_id", $request->transportor_id)
            ->where("driver_id", $request->driver_id)
            ->first();

        if ($existingJob) {
            // Update the existing record with the new status
            DB::table("get_job")
                ->where("job_id", $request->job_id)
                ->where("transportor_id", $request->transportor_id)
                ->where("driver_id", $request->driver_id)
                ->update(["status" => $request->status]);

            return response()->json([
                "success" => true,
                "message" => "Job status updated successfully.",
            ]);
        } else {
            // Insert a new record if the combination doesn't exist
            DB::table("get_job")->insert([
                "job_id" => $request->job_id,
                "transportor_id" => $request->transportor_id,
                "driver_id" => $request->driver_id,
                "status" => $request->status,
                "created_at" => now(),
                "updated_at" => now(),
            ]);

            return response()->json([
                "success" => true,
                "message" => "New job status inserted successfully.",
            ]);
        }
    }

    public function updateStatus(Request $request)
    {
        $job = Job::where("id", $request->id)
            ->where("transporter_id", $request->transporter_id)
            ->first();

        if ($job) {
            $job->active_inactive = $request->status;
            $job->save();

            return response()->json([
                "success" => true,
                "message" => "Status updated successfully!",
                "status" => $job->active_inactive,
            ]);
        }

        return response()->json(
            ["success" => false, "message" => "Job not found!"],
            404
        );
    }

    public function updateClosedStatus(Request $request)
    {
        $job = Job::where("id", $request->id)
            ->where("transporter_id", $request->transporter_id)
            ->first();

        if ($job) {
            $job->closed_job = $request->status;
            $job->save();

            return response()->json([
                "success" => true,
                "message" => "Status updated successfully!",
                "status" => $job->closed_job,
            ]);
        }

        return response()->json(
            ["success" => false, "message" => "Job not found!"],
            404
        );
    }

    /*
        driver section
    */
    public function driver()
    {
        if (empty(Session::get("role") == "transporter")) {
            return redirect("/");
        }

        $id = Session::get("id");

        $user = User::where("sub_id", $id)
            ->where("role", "=", "driver")
            ->get();

        return view("transporter/driver", compact("user"));
    }

    public function edit_driver(Request $request, $id)
    {
        if (empty(Session::get("role") == "transporter")) {
            return redirect("/");
        }

        $user = User::find($id);
        $states = State::all();
        $selectedState = $user->states;
        
        return view("transporter/edit_driver",compact("user", "states", "selectedState")
        );
    }

    public function update_driver(Request $request, $id)
    {
        if (Session::get("role") != "transporter") {
            return redirect("/");
        }
        $data = $request->validate([
            "name" => "required",
            "mobile" => "required|numeric|digits:10|unique:users,mobile",
            "password" => "required|confirmed",
            "DOB" => "required",
            "vehicle_type" => "required",
            "Type_of_License" => "required",
            "Aadhar_Number" => "required",
            "Aadhar_Photo" => "required",
            "Driving_License" => "required",
        ]);

        $subId = Session::get("id");

        $student = User::find($id);
        $student->role = "driver";
        $student->sub_id = $subId;
        $student->name = $request->input("name");
        $student->email = $request->input("email");
        $student->mobile = $request->input("mobile");
        $student->Father_Name = $request->input("Father_Name");
        $student->DOB = $request->input("DOB");
        $student->vehicle_type = $request->input("vehicle_type");
        $student->Sex = $request->input("Sex");
        $student->Marital_Status = $request->input("Marital_Status");
        $student->Highest_Education = $request->input("Highest_Education");
        $student->Driving_Experience = $request->input("Driving_Experience");
        $student->Type_of_License = $request->input("Type_of_License");
        $student->Expiry_date_of_License = $request->input(
            "Expiry_date_of_License"
        );
        $student->address = $request->input("address");
        $student->city = $request->input("city");
        $student->states = $request->input("states");
        $student->Preferred_Location = $request->input("Preferred_Location");
        $student->Current_Monthly_Income = $request->input(
            "Current_Monthly_Income"
        );
        $student->Expected_Monthly_Income = $request->input(
            "Expected_Monthly_Income"
        );
        $student->Aadhar_Number = $request->input("Aadhar_Number");

        if ($request->hasFile("images")) {
            $oldImagePath = public_path($student->images);
            if (file_exists($oldImagePath) && $student->images) {
                unlink($oldImagePath);
            }
            $image = $request->file("images");
            $imageName = time() . "." . $image->getClientOriginalExtension();
            $image->move(public_path("images"), $imageName);
            $student->images = "images/" . $imageName;
        }

        if ($request->hasFile("Aadhar_Photo")) {
            $oldImagePath = public_path($student->Aadhar_Photo);
            if (file_exists($oldImagePath) && $student->Aadhar_Photo) {
                unlink($oldImagePath);
            }
            $image = $request->file("Aadhar_Photo");
            $imageName = time() . "." . $image->getClientOriginalExtension();
            $image->move(public_path("images"), $imageName);
            $student->Aadhar_Photo = "images/" . $imageName;
        }

        if ($request->hasFile("Driving_License")) {
            $oldImagePath = public_path($student->Driving_License);
            if (file_exists($oldImagePath) && $student->Driving_License) {
                unlink($oldImagePath);
            }
            $image = $request->file("Driving_License");
            $imageName = time() . "." . $image->getClientOriginalExtension();
            $image->move(public_path("images"), $imageName);
            $student->Driving_License = "images/" . $imageName;
        }

        $student->update();
        Session::flash("success", "Driver Update successfully!");
        return redirect("transporter/driver");
    }

    public function driver_delete(Request $request, $id)
    {
        if (Session::get("role") != "transporter") {
            return redirect("/");
        }
        User::find($id)->delete();
        Session::flash("success", "Record Delete successful!");
        return redirect("transporter/view-transportor-driver");
    }
}
