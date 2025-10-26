<?php

namespace App\Http\Controllers;

use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Hash;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Session;
use Illuminate\Validation\Rules\Password;
use Illuminate\Support\Facades\Mail;
use App\Models\User;
use App\Models\Blog;
use App\Models\Brand;
use App\Models\Trucklist;
use App\Models\Truckimage;
use App\Models\Blogcategory;
use App\Models\Fueltype;
use App\Models\Budget;  
use App\Models\VehicleApplication; 
use App\Models\Gvm;
use App\Models\Vehicletype;
use App\Models\TyresCount;
use App\Models\WebContactLead;
use Illuminate\Support\Facades\Http;
use DB;

class FrontController extends Controller
{
    public function index()
    {
        $brand = Brand::all();
        $firstBrandId = $brand[0]->id;
        $blog = Blog::join('blog_categorys', 'blogs.cat_id', '=', 'blog_categorys.id')
            ->select('blogs.*', 'blog_categorys.cat_name as category_name')
            ->orderBy('blogs.created_at', 'desc')
            ->limit(3)
            ->get();
        $Trucklist = Trucklist::join('brands', 'trucklist.brand_id', '=', 'brands.id')
                ->select('trucklist.*', 'brands.*')
                ->where('brands.id',$firstBrandId)
                ->get();
            
        return view('Fronted/index', compact('blog','Trucklist', 'brand'));
    }
    
    public function show($id)
    {
        $Trucklist = Trucklist::join('brands', 'trucklist.brand_id', '=', 'brands.id')
            ->select('trucklist.*', 'brands.*')
            ->where('brands.id', $id)
            ->get();
        // dd($Trucklist);
        return view('Fronted/get_brand_by_id', compact('Trucklist'));
    }


    public function about_us()
    
    {
         $metaTitle = 'About Us | TruckMitr - Innovating the Trucking Industry';
        $metaDescription = 'About TruckMitr: We’re committed to excellence in trucking. Discover our mission to simplify and innovate the trucking industry.';
        
        return view('Fronted/aboutus', [
            'metaTitle' => $metaTitle,
            'metaDescription' => $metaDescription,
            
            ]);
    }
    
    
    public function compare2()   
    {
       
        $pairs = DB::table('trucklist as t1')
        ->join('trucklist as t2', function ($join) {
            $join->on('t1.compare_id', '=', 't2.compare_id')
                ->whereColumn('t1.id', '<', 't2.id'); 
        })
        ->where('t1.compare_id', '!=', 0) 
        ->where('t2.compare_id', '!=', 0) // Add condition for t2 (if needed)
        ->select('t1.oem_name as truck1_name','t1.Vehicle_model as Vehicle_models','t1.Price_Range as p1','t1.max_price as pp1', 't2.Price_Range as p2','t2.max_price as pp2','t1.slug as s1', 't2.slug as s2', 't2.oem_name as truck2_name','t2.Vehicle_model as Vehicle_modelss','t1.images as truck1_image', 't2.images as truck2_image')
        ->get();
        return view('Fronted/compare2', ['result'=>$pairs]);
    }
    
    public function videos_grid()
    {
        return view('Fronted/videosgrid');
    }
	public function career_job()
    {
        return view('Fronted/career');
    }
			public function career_details()
    {
        return view('Fronted/career-details');
    }
    public function jobs_listing()
    {
        return view('Fronted/jobs_listing');
    }
    public function wishlist()
    {
        return view('Fronted/wishlist');
    }

    public function truckmitr()
    {
          $metaTitle = 'TruckMitr - Transforming the Trucking Experience';
        $metaDescription = "Explore TruckMitr’s innovative tools and solutions designed to empower truckers and transform the trucking industry.";
        return view('Fronted/truckmitr',[
            'metaTitle' => $metaTitle,
            'metaDescription' => $metaDescription,
        ]);
    }

    public function blogs()
    {
      
        $blog = Blog::join('blog_categorys', 'blogs.cat_id', '=', 'blog_categorys.id')
    ->select('blogs.*', 'blog_categorys.cat_name as category_name')
    ->orderBy('blogs.Created_at', 'desc') 
    ->get();

        $metaTitle = 'Blogs | TruckMitr - Trucking Industry News & Tips';
        $metaDescription = "Explore TruckMitr’s blogs for the latest trucking industry news, tips, and expert advice. Stay ahead in your trucking journey.";
        
        return view('Fronted/blog', ['blog' => $blog],[
            'metaTitle' => $metaTitle,
            'metaDescription' => $metaDescription,
        ]);
    }

    public function faq()
    {
        $metaTitle = 'TruckMitr FAQ - Quick Help & Trucking Insights';
        $metaDescription = "TruckMitr’s FAQ provides answers to your trucking questions. Learn more about our services and get the support you need.";
        return view('Fronted/faq',[
            'metaTitle' => $metaTitle,
            'metaDescription' => $metaDescription,
        ]);
    }

    public function cancellation_and_refund_policy()
    {
         $metaTitle = 'Cancellation and refund policy | TruckMitr - Get Help with Trucking Services';
        $metaDescription = "Cancellation and refund policy";
        return view('Fronted/cancellation-and-refund-policy',[
            'metaTitle' => $metaTitle,
            'metaDescription' => $metaDescription,
        ]);
    }
    
     public function shipping_delivery()
    {
         $metaTitle = 'Shipping Delivery | TruckMitr - Get Help with Trucking Services';
        $metaDescription = "Shipping Delivery";
        return view('Fronted/shipping-delivery',[
            'metaTitle' => $metaTitle,
            'metaDescription' => $metaDescription,
        ]);
    }
    
      public function contact()
    {
         $metaTitle = 'Contact Us | TruckMitr - Get Help with Trucking Services';
        $metaDescription = "Reach out to TruckMitr for trucking solutions and expert support. We’re here to help with your questions and needs.";
        return view('Fronted/contact',[
            'metaTitle' => $metaTitle,
            'metaDescription' => $metaDescription,
        ]);
    }
    
    public function service()
    {
         $metaTitle = 'Service Us | TruckMitr - Get Help with Trucking Services';
        $metaDescription = "Reach out to TruckMitr for trucking solutions and expert support. We’re here to help with your questions and needs.";
        return view('Fronted/service',[
            'metaTitle' => $metaTitle,
            'metaDescription' => $metaDescription,
        ]);
    }
    
    public function team()
    {
         $metaTitle = 'Our Team | TruckMitr - Get Help with Trucking Services';
        $metaDescription = "Reach out to TruckMitr for trucking solutions and expert support. We’re here to help with your questions and needs.";
        return view('Fronted/our-team',[
            'metaTitle' => $metaTitle,
            'metaDescription' => $metaDescription,
        ]);
    }
    
    public function contact_submit(Request $request)
    {
        // Validate form fields
        $request->validate([
            'names' => 'required',
            'email' => 'required|email',
            'mobile' => 'required',
            'city' => 'required',
            'state' => 'required',
            'category' => 'required',
            'message' => 'required',
            'g-recaptcha-response' => 'required'
        ], [
            'g-recaptcha-response.required' => 'Please verify that you are not a robot.'
        ]);
    
        // Get captcha response
        $captchaResponse = $request->input('g-recaptcha-response');
    
        // Verify with Google API
        $verify = Http::asForm()->post('https://www.google.com/recaptcha/api/siteverify', [
            'secret'   => '6LcJf-kqAAAAAGbc8hRolZaqYgRR9h_ycw7aFQ55',
            'response' => $captchaResponse,
            'remoteip' => $request->ip(),
        ]);
    
        // Get response data
        $responseData = $verify->json();
    
        // Debugging - remove this after confirming the response
        // dd($responseData);
    
        // Check reCAPTCHA validation
        if (!isset($responseData['success'])) {
            return back()->withErrors(['captcha' => 'Captcha verification failed. Please try again.']);
        }
    
        // Prepare email data
        $data = [
            'names' => $request->names,
            'email' => $request->email,
            'mobile' => $request->mobile,
            'city' => $request->city,
            'state' => $request->state,
            'category' => $request->category,
            'user_message' => $request->message,
        ];
    
		WebContactLead::create($data);
		
        // Send email
        Mail::send('emails.Contact', $data, function ($message) use ($data) {
            $message->to('contact@truckmitr.com')->subject('Contact Us Form Submission');
        });
    
        // Redirect back with success message
        return back()->with('success', 'Your message has been sent successfully!');
    }
    
    public function track_submit(Request $request)
    {
        $request->validate([
            'names' => 'required',
            'mobile' => 'required',
            'city' => 'required',
        ]);

        $data = [
            'names' => $request->names,
            'mobile' => $request->mobile,
            'city' => $request->city,
        ];
        Mail::send('emails.Inquiry', $data, function ($message) use ($data) {
         $message->to('contact@truckmitr.com')->subject('Truck Inquiry Form Submission');
        });
        return back()->with('success', 'Your message has been sent successfully!');
    }
    
    public function blog_details(Request $request, $slug)
    {
        $blog = Blog::all();

        $blogs = Blog::join('blog_categorys', 'blogs.cat_id', '=', 'blog_categorys.id')
            ->select('blogs.*', 'blog_categorys.cat_name as category_name')
            ->where('slug', $slug)
            ->firstOrFail();
    
        $blog_cat = Blog::join('blog_categorys', 'blogs.cat_id', '=', 'blog_categorys.id')
            ->select('blog_categorys.cat_name as category_name', DB::raw('COUNT(blogs.id) as blog_count'))
            ->groupBy('blog_categorys.cat_name')
            ->get();

        return view('Fronted.blog_details', compact('blog_cat', 'blogs', 'blog'));
    }

    public function product(Request $request)
    {
        $Brand = Brand::all();
        $brand = $request->input('brand');
        $model = $request->input('model');
        if($brand!='' && $model==''){
            $Trucklist = Trucklist::join('brands', 'trucklist.brand_id', '=', 'brands.id')
            ->where('trucklist.brand_id', $brand)
            ->select('trucklist.*', 'brands.*')
            ->get();
            
            $Trucklistcount = Trucklist::join('brands', 'trucklist.brand_id', '=', 'brands.id')
            ->select('brands.name', 'brands.id as bid', DB::raw('COUNT(trucklist.id) as truck_count'))
            ->where('trucklist.brand_id', $brand)
            ->groupBy('brands.id','brands.name')
            ->get();
            
        }else if($model!='' && $brand==''){
            
            $Trucklist = Trucklist::join('brands', 'trucklist.brand_id', '=', 'brands.id')
                ->select('trucklist.*', 'brands.*')
                ->where('trucklist.Vehicle_model', $model)
                ->get();
                
            $Trucklistcount = Trucklist::join('brands', 'trucklist.brand_id', '=', 'brands.id')
                ->select('brands.name', 'brands.id as bid', DB::raw('COUNT(trucklist.id) as truck_count'))
                ->where('trucklist.Vehicle_model', $model)
                ->groupBy('brands.id','brands.name')
                ->get();
        }else if($model!='' && $brand!=''){
            $Trucklist = Trucklist::join('brands', 'trucklist.brand_id', '=', 'brands.id')
                ->select('trucklist.*', 'brands.*')
                ->where('trucklist.brand_id', $brand)
                ->where('trucklist.Vehicle_model', $model)
                ->get();
                
            $Trucklistcount = Trucklist::join('brands', 'trucklist.brand_id', '=', 'brands.id')
                ->select('brands.name', 'brands.id as bid', DB::raw('COUNT(trucklist.id) as truck_count'))
                ->where('trucklist.brand_id',  $brand)
                ->where('trucklist.Vehicle_model', $model)
                ->groupBy('brands.id','brands.name')
                ->get();
        }else{
            $Trucklist = Trucklist::join('brands', 'trucklist.brand_id', '=', 'brands.id')
                ->select('trucklist.*', 'brands.*')
                ->paginate(12);
                
            $Trucklistcount = Trucklist::join('brands', 'trucklist.brand_id', '=', 'brands.id')
            ->select('brands.name', 'brands.id as bid', DB::raw('COUNT(trucklist.id) as truck_count'))
            ->groupBy('brands.id', 'brands.name') // Group by both id and name
            ->get();
        }

        $totalTrucks = $Trucklist->count();
        
         //$Fueltype = Fueltype::select('fuel_type_name')->get();
         $Fueltype = Fueltype::pluck('fuel_type_name');
         $Budget = Budget::pluck('budget_name');
         $VehicleApplication = VehicleApplication::pluck('vehicle_application_name');
         $TyresCount = TyresCount::pluck('tyres_type');
         $Gvm = Gvm::pluck('gvm_name');
         $Vehicletype = Vehicletype::pluck('vehicle_name');
            
        return view('Fronted/filter', compact('Brand','Trucklist','Trucklistcount','totalTrucks','Fueltype','Budget','VehicleApplication','TyresCount','Gvm','Vehicletype'));
    }
    
    public function filterTrucks(Request $request){
        $query = Trucklist::query();

        // Apply brand filter
        if ($request->brands) {
            $query->whereIn('brand_id', $request->brands);
        }
    
        // Apply budget filter
        if ($request->budgets) {
            $query->where(function ($query) use ($request) {
                foreach ($request->budgets as $budget) {
                    if ($budget === 'Below 10 lakh') {
                        $query->orWhereRaw("CAST(REPLACE(Price_Range, ' lakhs', '') AS UNSIGNED) < ?", [10]);
                    } elseif ($budget === 'Above 50 lakh') {
                        $query->orWhereRaw("CAST(REPLACE(max_price, ' lakhs', '') AS UNSIGNED) >= ?", [50]);
                    } else {
                        [$min, $max] = explode(' - ', str_replace(' lakhs', '', $budget));
        
                        $query->orWhere(function ($subQuery) use ($min, $max) {
                            $subQuery->whereRaw("CAST(REPLACE(Price_Range, ' lakhs', '') AS UNSIGNED) >= ?", [(int)$min])
                                ->whereRaw("CAST(REPLACE(max_price, ' lakhs', '') AS UNSIGNED) <= ?", [(int)$max]);
                        });
                    }
                }
            });
        }
    
        // Apply fuel type filter
        if ($request->fuelTypes) {
            $query->whereIn('fule_type', $request->fuelTypes);
        }
    
        // Apply vehicle application filter
        if ($request->applications) {
            $query->whereIn('add_application', $request->applications);
        }
    
        // Apply GVW filter
        if ($request->gvws) {
            $query->where(function ($query) use ($request) {
                foreach ($request->gvws as $gvw) {
                    [$min, $max] = explode(' - ', $gvw);
                    $query->orWhereBetween('gvm', [(int)$min, (int)$max]);
                }
            });
        }
    
        // Apply vehicle type filter
        if ($request->vehicleTypes) {
            $query->whereIn('Vehicle_type', $request->vehicleTypes);
        }
    
        // Apply tyres count filter
        if ($request->tyresCounts) {
            $query->whereIn('tyres_count', $request->tyresCounts);
        }
        
        if ($request->sort) {
            switch ($request->sort) {
                case 'a-z':
                    $query->orderBy('oem_name', 'asc'); // Assuming the truck name field is 'name'
                    break;
                case 'z-a':
                    $query->orderBy('oem_name', 'desc');
                    break;
                case 'low-high':
                    $query->orderByRaw('CAST(Price_Range AS UNSIGNED) asc'); // Sorting by Price_Range numerically
                    break;
                case 'high-low':
                    $query->orderByRaw('CAST(Price_Range AS UNSIGNED) desc'); // Sorting by Price_Range numerically
                    break;
                case 'latest':
                    $query->orderBy('Created_at', 'desc');
                    break;
            }
        }
    
        // Fetch the filtered trucks
        // $trucks = $query->get();
        $trucks = $query->paginate(12);
        // $pagination = $pagination;
    
        // Render the HTML for the filtered trucks
        //$html = view('partials.truck-list', compact('filteredTrucks'))->render();
        $totalCount = $query->count();
        // return response()->json(['html' => $html]);
        return view('Fronted/filterbrand', compact('trucks', 'totalCount'));
    }
    
    
    public function getSlug(Request $request){
        $bid = $request->input('brands');
        $mid = $request->input('model');
        $slug = Trucklist::where('brand_id', $bid)
             ->where('Vehicle_model', $mid)
             ->value('slug'); // Fetch the 'slug' column
        echo $slug;
    }
    
    public function getTrucksByPriceRange(Request $request)
    {
        // Validate the price inputs
        $validated = $request->validate([
            'min_price' => 'required|numeric|min:100000',
            'max_price' => 'required|numeric|min:100000',
        ]);

        // Extract values from the request
        $minPrice = $validated['min_price'];
        $maxPrice = $validated['max_price'];

        // Query the trucks within the price range
        $trucks = Trucklist::whereBetween('Price_Range', [$minPrice, $maxPrice])->get();

        // Return the trucks as a JSON response
        return view('Fronted/filterbrand', compact('trucks'));
    }
    
    public function compareProduct(Request $request, $slug1, $slug2 = null, $slug3 = null, $slug4 = null){
        $slugs = [$slug1, $slug2, $slug3, $slug4];
        $slugs = array_filter($slugs, function($slug) {
                return !is_null($slug);
            });
        $products = DB::table('trucklist')
        ->select('id','brand_id','oem_name','slug','Vehicle_type','Product_specification','Vehicle_model','Engine_make','Engine_model',
            'Engine_HP','Engine_capacity','No_of_cylinders','MAX_Engine_output','MAX_Torque','OD_of_clutch_lining','Clutch_type','Type_of_actuation',
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
            'max_price',
            'images',
            'Description',
            'status'
        )
        ->whereIn('slug', $slugs)
        ->get();

        $productsc = $products->map(function ($product) {
            return [
                'id' => $product->id,
                'brand_id' => $product->brand_id,
                'oem_name' => $product->oem_name,
                'slug' => $product->slug,
                'Vehicle_type' => $product->Vehicle_type,
                'Product_specification' => $product->Product_specification,
                'Vehicle_model' => $product->Vehicle_model,
                'Engine_make' => $product->Engine_make,
                'Engine_model' => $product->Engine_model,
                'Engine_HP' => $product->Engine_HP,
                'Engine_capacity' => $product->Engine_capacity,
                'No_of_cylinders' => $product->No_of_cylinders,
                'MAX_Engine_output' => $product->MAX_Engine_output,
                'MAX_Torque' => $product->MAX_Torque,
                'OD_of_clutch_lining' => $product->OD_of_clutch_lining,
                'Clutch_type' => $product->Clutch_type,
                'Type_of_actuation' => $product->Type_of_actuation,
                'Gear_Box_Model' => $product->Gear_Box_Model,
                'No_of_gears' => $product->No_of_gears,
                'Min_Turning_circle_dia' => $product->Min_Turning_circle_dia,
                'Wheel_base' => $product->Wheel_base,
                'Overall_Length' => $product->Overall_Length,
                'Overall_Height' => $product->Overall_Height,
                'Overall_Width' => $product->Overall_Width,
                'Ground_clearance' => $product->Ground_clearance,
                'Max_Permissible_GVW' => $product->Max_Permissible_GVW,
                'Fuel_tank_Capacity' => $product->Fuel_tank_Capacity,
                'Steering_type' => $product->Steering_type,
                'Suspension_Type_Front' => $product->Suspension_Type_Front,
                'Suspension_Type_Rear' => $product->Suspension_Type_Rear,
                'Wheels' => $product->Wheels,
                'No_of_tyres' => $product->No_of_tyres,
                'Battery' => $product->Battery,
                'Brakes_type' => $product->Brakes_type,
                'Parking_brake' => $product->Parking_brake,
                'Auxiliary_Braking_System' => $product->Auxiliary_Braking_System,
                'Frame_type' => $product->Frame_type,
                'Diesel_Exhaust_Fluid' => $product->Diesel_Exhaust_Fluid,
                'Front_axle_Type' => $product->Front_axle_Type,
                'Rear_axle_Model' => $product->Rear_axle_Model,
                'Rear_axle_Ratio' => $product->Rear_axle_Ratio,
                'Cabin_type' => $product->Cabin_type,
                'Standard_features' => $product->Standard_features,
                'Maximum_gradebility' => $product->Maximum_gradebility,
                'Price_Range' => $product->Price_Range,
                'max_price' => $product->max_price,
                'images' => $product->images,
                'Description' => $product->Description,
                'status' => $product->status,
            ];
        })->toArray();
        return view('Fronted/compare', compact('productsc'));
    }
    
    public function allbrand(Request $request, $id)
     {
        $output = "";
        $truckname = DB::table('trucklist')->select('Vehicle_model', 'id')->where('brand_id', $id)->get();

        $output .= '<option value="" >Select Model</option>';
        if ($truckname) {
            foreach ($truckname as $product) {

                $output .= '<option value="' . $product->Vehicle_model . '">' . $product->Vehicle_model . '</option>';
            }
            return Response($output);
        }
     }

    public function product_details(Request $request, $slug)
    {
        
        $Trucklist = Trucklist::join('brands', 'trucklist.brand_id', '=', 'brands.id') 
            ->select('trucklist.*', 'brands.*') 
            ->where('trucklist.slug', $slug)
            ->firstOrFail();

     //dd($Trucklist); die;
        $TruckNew = Trucklist::join('brands', 'trucklist.brand_id', '=', 'brands.id')
            ->select('trucklist.*', 'brands.*')
            ->orderBy('trucklist.created_at', 'desc')
            ->limit(8)
            ->get();

        $Truck = Trucklist::join('brands', 'trucklist.brand_id', '=', 'brands.id')
            ->select('trucklist.*', 'brands.*')
            ->orderBy('trucklist.created_at', 'desc')
            ->limit(8)
            ->get();
        $truck_detail = Trucklist::select('id')->where('slug', $slug)->firstOrFail();
        
        $image = DB::table('truck_images')->where('truck_id', $truck_detail->id)->get();
       
        return view('Fronted/product', compact('Trucklist', 'TruckNew', 'Truck','image'));
    }

    public function privacy_policy()
    {
        $metaTitle = ' Privacy Policy | TruckMitr - Transparent Data Practices';
        $metaDescription = "TruckMitr's Privacy Policy ensures the security of your data. Discover how we protect your information and maintain trust with transparent practices.";
        return view('Fronted/privacy-policy',[
            'metaTitle' => $metaTitle,
            'metaDescription' => $metaDescription,
        ]);
    }

    public function term_of_use()
    {
        $metaTitle = 'Terms of Use | TruckMitr - Service Usage Guidelines';
        $metaDescription = "Learn about TruckMitr's Terms of Use, including user responsibilities and platform rules. Ensure a safe and compliant experience";
        return view('Fronted/term-of-use',[
            'metaTitle' => $metaTitle,
            'metaDescription' => $metaDescription,
        ]);
    }
    public function quiz()
    {
        $metaTitle = 'About Us - Company Name';
        $metaDescription = 'Learn more about our company, our values, and our mission.';
        return view('Fronted/quiz',[
            'metaTitle' => $metaTitle,
            'metaDescription' => $metaDescription,
        ]);
    }
	
}
?>