<?php

namespace App\Http\Controllers;

use Session;
use Illuminate\Http\Request;
use App\Models\Video;
use App\Models\Job;
use App\Models\ApplyJob;
use App\Models\User;
use App\Models\Vehicletype;
use App\Models\State;
use App\Models\Quiz;
use App\Models\Videowatch;
use App\Models\HealthHygine;
use DB;


class DriverController extends Controller
{
    public function dashboard()
    {
        if (empty(Session::get("role") == "driver")) {
            return redirect("/");
        }

        $id = Session::get("id");

        $User = User::where("id", $id)->first();

        //$totaljob = Job::where("status", 1)->sum("Job_Management");
        
         $totaljob = DB::table("jobs")
         ->where('status',1)
         ->where('active_inactive',1)
         ->count();

        $module = DB::table("modules")->get();

        return view("Drivers/dashboard", compact("User", "totaljob", "module"));
    }

    public function quizcount()
    {
        if (empty(Session::get("role") == "driver")) {
            return redirect("/");
        }

        $id = Session::get("id");

        $User = User::where("id", $id)->first();
        //   $module = DB::table('modules')->get();

        $module = DB::table("modules")
            ->join("quiz_results", "quiz_results.module_id", "=", "modules.id")
            ->where("quiz_results.user_id", $id)
            ->select("modules.id", DB::raw("MAX(modules.name) as name")) // Aggregating the name column
            ->groupBy("modules.id")
            ->get();

        return view("Drivers/quizcount", compact("module", "User"));
    }

    public function driver_profile()
    {
        if (empty(Session::get("role") == "driver")) {
            return redirect("/");
        }
        $id = Session::get("id");

        $user = User::where("id", $id)
            ->where("role", "=", "driver")
            ->first();
        $Vehicletype = Vehicletype::all();
        $states = State::all();
        $selectedState = $user->states;
      return view("Drivers/profile",compact("user", "Vehicletype", "selectedState", "states"));
    }

    public function driver_profile_update(Request $request)
    {
        if (empty(Session::get("role") == "driver")) {
            return redirect("/");
        }

        $id = Session::get("id");

        $request->validate(
            [
                "name" => "required",
                "Type_of_License" => "required",
                "mobile" => "required",
                "DOB" => "required|date",
                "License_Number" =>
                    "required|unique:users,License_Number," . $id . ",id",
                "Aadhar_Number" =>
                    "required|unique:users,Aadhar_Number," . $id . ",id",
                "vehicle_type" => "required",
                "Aadhar_Number" => [
                    "required",
                    "unique:users,Aadhar_Number," . $id . ",id",
                    "regex:/^[2-9]{1}[0-9]{11}$/",
                ],
                "vehicle_type" => "required",
                "Aadhar_Photo" => "nullable|image|mimes:jpeg,png,jpg|max:2048", // 2MB max
                "Driving_License" => [
                    "nullable",
                    "image",
                    "mimes:jpeg,png,jpg",
                    "max:2048",
                ],
            ],
            
            [
                "License_Number.unique" =>
                    "The Type of License is already in use.",
                    "Driving_License.unique" =>
                    "The Driver License is Reuired.",
                "Aadhar_Number.unique" =>
                    "The Aadhar Number is already registered.",
            ]
        );

        $student = User::find($id);

        $student->name = $request->input("name");
        $student->Type_of_License = $request->input("Type_of_License");
        $student->mobile = $request->input("mobile");
        $student->email = $request->input("email");
        $student->Father_Name = $request->input("Father_Name");
        $student->DOB = $request->input("DOB");
        $student->vehicle_type = $request->input("vehicle_type");
        $student->Sex = $request->input("Sex");
        $student->Marital_Status = $request->input("Marital_Status");
        $student->Highest_Education = $request->input("Highest_Education");
        $student->Driving_Experience = $request->input("Driving_Experience");
        $student->Type_of_License = $request->input("Type_of_License");
        $student->License_Number = $request->input("License_Number");
        $student->Expiry_date_of_License = $request->input("Expiry_date_of_License");
        $student->address = $request->input("address");
        $student->city = $request->input("city");
        $student->states = $request->input("states");
        $student->Preferred_Location = $request->input("Preferred_Location");
        $student->Current_Monthly_Income = $request->input("Current_Monthly_Income");
        $student->Expected_Monthly_Income = $request->input("Expected_Monthly_Income");
        $student->Aadhar_Number = $request->input("Aadhar_Number");
        $student->job_placement = $request->input("job_placement");
        $student->previous_employer = $request->input("previous_employer");

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
        Session::flash("success", "Profile Update successfully!");
        return redirect("driver/profile");
    }
    
    // public function driver_profile_update(Request $request)
    // {
    //     if (empty(Session::get("role") == "driver")) {
    //         return redirect("/");
    //     }
    
    //     $id = Session::get("id");
    
    //     $request->validate(
    //         [
    //             "name" => "required",
    //             "mobile" => "required",
    //             "DOB" => "required|date",
    //             "Type_of_License" => "required|unique:users,Type_of_License," . $id . ",id",
    //             "Aadhar_Number" => [
    //                 "required",
    //                 "unique:users,Aadhar_Number," . $id . ",id",
    //                 "regex:/^[2-9]{1}[0-9]{11}$/",
    //             ],
    //             "vehicle_type" => "required",
    //             "Aadhar_Photo" => "nullable|image|mimes:jpeg,png,jpg|max:2048", // 2MB max
    //             "Driving_License" => [
    //                 "nullable",
    //                 "image",
    //                 "mimes:jpeg,png,jpg",
    //                 "max:2048",
    //             ],
    //         ],
    //         [
    //             "name.required" => "The name field is required.",
    //             "mobile.required" => "The mobile number is required.",
    //             "DOB.required" => "The date of birth is required.",
    //             "DOB.date" => "The date of birth must be a valid date.",
    //             "Type_of_License.unique" => "The Type of License is already in use.",
    //             "Aadhar_Number.unique" => "The Aadhar Number is already registered.",
    //             "Aadhar_Number.regex" => "The Aadhar Number must be a valid 12-digit number.",
    //             "vehicle_type.required" => "The vehicle type is required.",
    //             "Aadhar_Photo.image" => "The Aadhar Photo must be an image.",
    //             "Aadhar_Photo.mimes" => "The Aadhar Photo must be a file of type: jpeg, png, jpg.",
    //             "Aadhar_Photo.max" => "The Aadhar Photo must not exceed 2MB.",
    //             "Driving_License.image" => "The Driving License must be an image.",
    //             "Driving_License.mimes" => "The Driving License must be a file of type: jpeg, png, jpg.",
    //             "Driving_License.max" => "The Driving License must not exceed 2MB.",
    //         ]
    //     );
    
    //     $student = User::find($id);
    
    //     $student->fill($request->all());
    
    //     if ($request->hasFile("Aadhar_Photo")) {
    //         $oldImagePath = public_path($student->Aadhar_Photo);
    //         if (file_exists($oldImagePath) && $student->Aadhar_Photo) {
    //             unlink($oldImagePath);
    //         }
    //         $image = $request->file("Aadhar_Photo");
    //         $imageName = time() . "_aadhar." . $image->getClientOriginalExtension();
    //         $image->move(public_path("images"), $imageName);
    //         $student->Aadhar_Photo = "images/" . $imageName;
    //     }
    
    //     if ($request->hasFile("Driving_License")) {
    //         $oldImagePath = public_path($student->Driving_License);
    //         if (file_exists($oldImagePath) && $student->Driving_License) {
    //             unlink($oldImagePath);
    //         }
    //         $image = $request->file("Driving_License");
    //         $imageName = time() . "_license." . $image->getClientOriginalExtension();
    //         $image->move(public_path("images"), $imageName);
    //         $student->Driving_License = "images/" . $imageName;
    //     }
    
    //     $student->update();
    //     Session::flash("success", "Profile updated successfully!");
    //     return redirect("driver/profile");
    // }


    public function jobs()
    {
        if (empty(Session::get("role") == "driver")) {
            return redirect("/");
        }

        $id = Session::get("id"); // Get driver ID from session
        $user = User::where("id", $id)->first();
        
        $expectedIncome = $user->Expected_Monthly_Income;
        $requiredExperience = $user->Driving_Experience;
        
        $job = DB::table("jobs")
            ->leftJoin('applyjobs', function ($join) use ($id) {
                $join->on('jobs.id', '=', 'applyjobs.job_id')
                     ->where('applyjobs.driver_id', '=', $id);
            })
            ->whereNull('applyjobs.id') // Exclude jobs already applied for
            ->where("vehicle_type", $user->vehicle_type)
            ->where("status", 1)
            ->where("active_inactive", 1)
            ->whereRaw(
                '? BETWEEN CAST(SUBSTRING_INDEX(Salary_Range, "-", 1) AS UNSIGNED) AND CAST(SUBSTRING_INDEX(Salary_Range, "-", -1) AS UNSIGNED)',
                [$expectedIncome]
            )
            ->whereRaw(
                '? BETWEEN CAST(SUBSTRING_INDEX(Required_Experience, "-", 1) AS UNSIGNED) AND CAST(SUBSTRING_INDEX(Required_Experience, "-", -1) AS UNSIGNED)',
                [$requiredExperience]
            )
            ->whereRaw('Application_Deadline >= CURDATE()') // Exclude expired jobs
            ->select('jobs.*') // Select only job fields
            ->get();
        $filter_show = 'no';
        return view("Drivers/jobs", compact("job", "user", "filter_show"));
    }
    public function Alljobs()
    {
        if (empty(Session::get("role") == "driver")) {
            return redirect("/");
        }

        $id = Session::get("id"); // Get driver ID from session
        $user = User::where("id", $id)->first();
        
        $expectedIncome = $user->Expected_Monthly_Income;
        $requiredExperience = $user->Driving_Experience;
        
        $job = DB::table("jobs")
            ->leftJoin('applyjobs', function ($join) use ($id) {
                $join->on('jobs.id', '=', 'applyjobs.job_id')
                    ->where('applyjobs.driver_id', '=', $id);
            })
            ->whereNull('applyjobs.id') // Exclude jobs already applied for
            ->where("status", 1)
            ->where("active_inactive", 1)
            ->whereRaw('Application_Deadline >= CURDATE()') // Exclude expired jobs
            ->select('jobs.*') // Select only job fields
            ->orderBy('created_at', 'desc') // Order by latest created_at
            ->get();
        $filter_show = 'yes';
        return view("Drivers/jobs", compact("job", "user", "filter_show"));
    }

    public function filterJob(Request $request)
    {
        if (empty(Session::get("role") == "driver")) {
            return redirect("/");
        }
        $query = Job::query();

        if ($request->salary) {
            $salaryRange = explode("-", $request->salary);
            if (count($salaryRange) == 2) {
                $query->whereBetween("Salary_Range", [
                    $salaryRange[0],
                    $salaryRange[1],
                ]);
            } elseif ($request->salary === "Above 50000") {
                $query->where("Salary_Range", ">", 50000);
            }
        }

        // Filter by experience
        if ($request->experience && $request->experience !== "all") {
            $experience = (int)$request->experience;
    
            // Filter jobs where the experience falls within the range
            $query->where(function ($subQuery) use ($experience) {
                $subQuery->whereRaw("
                    CAST(SUBSTRING_INDEX(Required_Experience, '-', 1) AS UNSIGNED) <= ?
                ", [$experience])
                ->whereRaw("
                    CAST(SUBSTRING_INDEX(Required_Experience, '-', -1) AS UNSIGNED) >= ?
                ", [$experience]);
            });
        }

        $job = $query->get();

        return view("Drivers/filterJob", compact("job"));
    }

    public function videos()
    {
        // Check if the user is a driver
        if (Session::get("role") != "driver") {
            return redirect("/login");
        }

        // Retrieve the driver ID from the session
        $driverId = Session::get("id");

        // Fetch the progress for the driver
        $progress = DB::table("driver_video_progress")
            ->where("driver_id", $driverId)
            ->pluck("is_completed", "video_id");

        // Retrieve and group the videos by module name
        $video = DB::table("Videos")
            ->join("video_topic", "video_topic.id", "=", "Videos.topic")
            ->join("modules", "modules.id", "=", "video_topic.mu_id")
            ->select("video_topic.*", "modules.name as module_name", "Videos.*")
            ->get()
            ->groupBy("module_name");

        // Get the first module and its first video
        // $firstModule = $video->keys()->first();
        // $firstVideo = $video[$firstModule]->first();

        // // Check if the first video is already completed or not
        // if (!isset($progress[$firstVideo->id]) || $progress[$firstVideo->id] != true) {
        //     // If the first video is not completed, unlock it
        //     $progress[$firstVideo->id] = true;
        // }

        // Check if there are any subsequent videos, and unlock them if the previous ones are completed
        // foreach ($video as $moduleVideos) {
        //     $previousCompleted = true; // Flag to track if all previous videos are completed

        //     foreach ($moduleVideos as $videoItem) {
        //         if (!$previousCompleted) {
        //             // If the previous video was not completed, lock the current video
        //             $progress[$videoItem->id] = false;
        //         } else {
        //             // If the current video is marked as completed, unlock the next one
        //             if (isset($progress[$videoItem->id]) && $progress[$videoItem->id] == true) {
        //                 $previousCompleted = true;
        //             } else {
        //                 $previousCompleted = false;
        //             }
        //         }
        //     }
        // }

        // Pass the videos and progress data to the view
        return view("Drivers/videos", compact("video", "progress"));
    }

    public function updateVideoProgress(Request $request)
    {
        if (empty(Session::get("role") == "driver")) {
            return redirect("/");
        }

        $driverId = session("id");
        $videoId = $request->input("video_id");
        $moduleId = $request->input("module_id");
        $isCompleted = $request->input("is_completed");

        // DriverVideoProgress::updateOrCreate(
        //     ['driver_id' => $driverId, 'video_id' => $videoId],
        //     ['is_completed' => $isCompleted]
        // );

        DB::table("driver_video_progress")->updateOrInsert(
            [
                "driver_id" => $driverId,
                "video_id" => $videoId,
                "module_id" => $moduleId,
                "quize_status" => 0,
            ], // where condition
            ["is_completed" => $isCompleted] // values to update or insert
        );

        return response()->json(["success" => true]);
    }

    public function quiz_list(Request $request, $moduleId)
    {
        if (Session::get("role") != "driver") {
            return redirect("/login");
        }

        $count_video = DB::table("Videos")
            ->where("module", $moduleId)
            ->count();
        $driverId = session("id");

        $count_seen_video = DB::table("driver_video_progress")
            ->where("module_id", $moduleId)
            ->where("driver_id", $driverId)
            ->count();

        if ($count_video != $count_seen_video) {
            return redirect("driver/videos");
        }
        $quizQuestions = Quiz::where("module", $moduleId)->get();
        //dd($quizQuestions);
        return view("Drivers/quiz", compact("quizQuestions"));
    }

    public function wishlist()
    {
		if (Session::get("role") != "driver") {
            return redirect("/");
        }
        return view("Drivers/wishlist");
    }

    public function applyJob(Request $request)
    {
        if (Session::get("role") != "driver") {
            return redirect("/login");
        }
        // Validate the request data
        $validated = $request->validate([
            "job_id" => "required",
            "transportor_id" => "required|integer",
        ]);

        // Create a new record in the applyjobs table
        $applyJob = applyjob::create([
            "driver_id" => Session::get("id"),
            "job_id" => $validated["job_id"],
            "contractor_id" => $validated["transportor_id"],
        ]);

        // Return the created record as a JSON response
        return response()->json(
            [
                "message" => "Job Applied Successfully",
            ],
            201
        );
    }
    
    public function appliedJob(Request $request)
    {
        if (Session::get("role") != "driver") {
            return redirect("/login");
        }
        $id = Session::get("id");
        $user = User::where("id", $id)->first();

        
        $job = DB::table('jobs')
        ->join('applyjobs', function ($join) {
            $join->on('jobs.id', '=', 'applyjobs.job_id')
                 ->on('applyjobs.contractor_id', '=', 'jobs.transporter_id');
        })
        ->where('applyjobs.driver_id', $id)
        ->select(
            'jobs.id as job_id',
            'jobs.job_id as job_unique_id',
            'jobs.transporter_id',
            'jobs.job_title',
            'jobs.job_location',
            'jobs.Required_Experience',
            'jobs.Salary_Range',
            'jobs.Type_of_License',
            'jobs.Preferred_Skills',
            'jobs.Application_Deadline',
            'jobs.Job_Management',
            'jobs.Job_Description',
            'jobs.vehicle_type',
            'jobs.status',
            'jobs.active_inactive',
            'jobs.closed_job',
            'jobs.Created_at as job_created_at',
            'jobs.Updated_at as job_updated_at',
            'applyjobs.id as applyjob_id',
            'applyjobs.driver_id',
            'applyjobs.contractor_id',
            'applyjobs.created_at as applyjob_created_at',
            'applyjobs.updated_at as applyjob_updated_at'
        )
        ->get();
        
        return view("Drivers/applyjobs", compact("job", "user"));
        
    }

    public function trackWatchTime(Request $request)
    {
        if (empty(Session::get("role") == "driver")) {
            return redirect("/");
        }
        //echo"sgasgag"; die;
        // Validate incoming request
        $validated = $request->validate([
            "videoSrc" => "required|string",
            "watchTime" => "required|integer",
            "isEnded" => "required|boolean",
        ]);

        $userId = session("id"); // Ensure user session is set
        $videoPath = $validated["videoSrc"];
        $watchTime = $validated["watchTime"];
        $isEnded = $validated["isEnded"];

        // Find the video record
        $video = Video::where("video", basename($videoPath))->first();

        if (!$video) {
            return response()->json(["error" => "Video not found"], 404);
        }

        // Update or create the watch time record
        $record = Videowatch::updateOrCreate(
            [
                "user_id" => $userId,
                "video_id" => $video->id,
            ],
            [
                "watch_time" => $isEnded
                    ? $video->duration
                    : max($watchTime, DB::raw("watch_time")),
            ]
        );

        return response()->json([
            "message" => "Watch time updated successfully",
        ]);
    }

    public function health_hygienes()
    {
        if (empty(Session::get("role") == "driver")) {
            return redirect("/");
        }

        $HealthHygine = HealthHygine::all();

        return view("Drivers/HealthHygine", compact("HealthHygine"));
    }

    public function modulelist()
    {
        return view("Drivers/modulelist");
    }
}
