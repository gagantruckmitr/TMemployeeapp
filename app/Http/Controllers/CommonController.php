<?php

namespace App\Http\Controllers;
use Illuminate\Support\Facades\Session;
use Illuminate\Http\Request;
use App\Models\User;
use App\Models\Job;
use App\Models\State;
use App\Models\Vehicletype;
use DB;
use App\Helpers\custom_helpers;
use Illuminate\Support\Facades\Response;
use App\Mail\JobMail;
use App\Imports\DriverImport;
use Maatwebsite\Excel\Facades\Excel;
use Illuminate\Support\Facades\Mail;
class CommonController extends Controller{
    
    public function exportCsv(){
        $csvFileName = 'state.csv';
    
        return Response::stream(function () {
            $handle = fopen('php://output', 'w');
    
            // Add CSV headers
            fputcsv($handle, ['ID', 'Name', 'Code']);
    
            // Fetch data and write to CSV
            $tableData = State::all();
            foreach ($tableData as $row) {
                fputcsv($handle, [$row->id, $row->name, $row->codes]);
            }
    
            fclose($handle);
        }, 200, [
            'Content-Type' => 'text/csv',
            'Content-Disposition' => 'attachment; filename="' . $csvFileName . '"',
        ]);
    }

    // public function updatemytruc(){
    //     // $roleCodes = [
    //     //     'driver' => 'TD',
    //     //     'transporter' => 'TP',
    //     //     'institute' => 'DS'
    //     // ];
    //     // $code = $roleCodes[$data['role']] ?? '';
    //     $users = DB::table('users')->get();
    //     foreach($users as $u){
    //         // echo "<pre>"; print_r($u->states);
    //        $state = DB::table('states')->where('id', $u->states)->first();
    //        $code = '';
    //        if($u->role=='driver'){
    //         $code = 'TD';
    //        }
    //        if($u->role=='transporter'){
    //         $code = 'TP';
    //        }
    //        if($u->role=='institute'){
    //         $code = 'DS';
    //        }
    //        $create = generate_nomenclature_id($code, $state->codes);
    //        DB::table('users')
    //         ->where('id', $u->id) // add your condition here
    //         ->update(['unique_idss' => $create]);
    //     }
    //     //generate_nomenclature_id($code, $state->codes);


    // }


    public function getTrucksByBrand($brand_id)
    {
        $trucks = DB::table('trucklist')->where('brand_id', $brand_id)->get();

        $options = '<option selected>Choose a variant...</option>';
        foreach ($trucks as $truck) {
            $options .= '<option value="'.$truck->slug.'">'.$truck->Vehicle_model.' - '.$truck->Engine_HP.' HP</option>';
        }

        return response()->json(['options' => $options]);
    }


    public function getTruckDetails($slug)
    {
        $truck = DB::table('trucklist')
        ->join('brands', 'trucklist.brand_id', '=', 'brands.id')
        ->where('trucklist.slug', $slug)
        ->select('trucklist.*', 'brands.name as brand_name') // Add other brand columns if needed
        ->first();


        if ($truck) {
            $html = '
            <div style="height: 44px; width: 75px" >
            <div class="o-bfyaNx o-brXWGL o-bqHweY dGcAoR">
                <img class="o-bXKmQE o-cgkaRG o-cQfblS o-bNxxEB" src="/public/'.$truck->images.'" alt="'.$truck->Vehicle_model.'" title="'.$truck->Vehicle_model.'" />
            </div>
            <div class="o-ccrPDo o-bkmzIL o-fzpihx" style="width:103px">'.$truck->Vehicle_model.'</div></div>
            <div class="o-ccrPDo o-bkmzIL o-fzpihx" style="width:103px">'.$truck->brand_name.'</div></div>';

            return response()->json(['html' => $html]);
        } else {
            return response()->json(['html' => '<div class="o-ccrPDo o-bkmzIL o-fzpihx">Truck Not Found</div>']);
        }
    }

    public function updateTruckList(Request $request)
    {
        $request->validate([
            'id' => 'required|integer',
            'compare_id' => 'required|integer',
        ]);

        $updated = DB::table('trucklist')
            ->where('id', $request->id)
            ->update(['compare_id' => $request->compare_id]);

        if ($updated) {
            return response()->json(['success' => true, 'message' => 'Record updated successfully!']);
        }

        return response()->json(['success' => false, 'message' => 'Failed to update record.']);
    }

    
}
