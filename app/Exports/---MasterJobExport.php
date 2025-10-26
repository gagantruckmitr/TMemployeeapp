<?php

namespace App\Exports;

use Illuminate\Contracts\View\View;
use Maatwebsite\Excel\Concerns\FromView;
use Illuminate\Http\Request;
use DB;

class MasterJobExport implements FromView
{
    protected $request;

    public function __construct(Request $request) {
        $this->request = $request;
    }

   public function view(): View
{
    // Subquery for applied drivers
    $appliedDrivers = DB::table('applyjobs as aj')
        ->join('users as d', 'aj.driver_id', '=', 'd.id')
        ->select(
            'aj.job_id',
            DB::raw("GROUP_CONCAT(d.unique_id SEPARATOR ', ') as applied_driver_tm_id"),
            DB::raw("GROUP_CONCAT(d.name SEPARATOR ', ') as applied_driver_name"),
            DB::raw("GROUP_CONCAT(d.mobile SEPARATOR ', ') as applied_driver_mobile")
        )
        ->groupBy('aj.job_id');

    // Subquery for selected drivers
    $selectedDrivers = DB::table('get_job as gj')
        ->join('users as gd', 'gj.driver_id', '=', 'gd.id')
        ->select(
            'gj.job_id',
            DB::raw("GROUP_CONCAT(gd.unique_id SEPARATOR ', ') as selected_driver_tm_id"),
            DB::raw("GROUP_CONCAT(gd.name SEPARATOR ', ') as selected_driver_name"),
            DB::raw("GROUP_CONCAT(gd.mobile SEPARATOR ', ') as selected_driver_mobile"),
            DB::raw("GROUP_CONCAT(gj.status SEPARATOR ', ') as gj_status"),
            DB::raw("GROUP_CONCAT(gj.created_at SEPARATOR ', ') as get_job_created"),
            DB::raw("GROUP_CONCAT(gj.updated_at SEPARATOR ', ') as get_job_updated")
        )
        ->groupBy('gj.job_id');

    // Subquery for payments
    $payments = DB::table('payments as p')
        ->where('p.payment_status', 'captured')
        ->select(
            'p.user_id',
            DB::raw("GROUP_CONCAT(p.id SEPARATOR ', ') as payment_ids"),
            DB::raw("GROUP_CONCAT(p.payment_status SEPARATOR ', ') as payment_statuses")
        )
        ->groupBy('p.user_id');

    // Main query
    $master_jobs = DB::table('jobs as j')
        ->leftJoin('users as t', 'j.transporter_id', '=', 't.id')
        ->leftJoinSub($appliedDrivers, 'applied', function ($join) {
            $join->on('j.id', '=', 'applied.job_id');
        })
        ->leftJoinSub($selectedDrivers, 'selected', function ($join) {
            $join->on('j.id', '=', 'selected.job_id');
        })
        ->leftJoinSub($payments, 'p', function ($join) {
            $join->on('p.user_id', '=', DB::raw("applied.applied_driver_tm_id"));
        })
        ->select(
            'j.id as job_id',
            'j.job_id',
            'j.job_title',
            'j.job_location',
            'j.created_at',
            'j.required_experience',
            'j.salary_range',
            'j.type_of_license',
            'j.status',
            'j.preferred_skills',
            'j.application_deadline',
            'j.number_of_drivers_required',
			'j.created_at as job_created_at',

            't.unique_id as transporter_tm_id',
            't.name as transporter_name',
            't.mobile as transporter_mobile',
            't.states as transporter_state',

            'applied.applied_driver_tm_id',
            'applied.applied_driver_name',
            'applied.applied_driver_mobile',

            'selected.selected_driver_tm_id',
            'selected.selected_driver_name',
            'selected.selected_driver_mobile',
            'selected.gj_status',
            'selected.get_job_created',
            'selected.get_job_updated',

            'p.payment_ids',
            'p.payment_statuses'
        )
        ->orderBy('j.id', 'desc')
        ->get();  // ✅ assign to $master_jobs

    return view('Admin.exports.masterjob', compact('master_jobs'));
}
}
