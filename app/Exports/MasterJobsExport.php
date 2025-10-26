<?php

namespace App\Exports;

use Illuminate\Support\Facades\DB;
use Maatwebsite\Excel\Concerns\FromCollection;
use Maatwebsite\Excel\Concerns\WithHeadings;
use PhpOffice\PhpSpreadsheet\Shared\Date;
use Maatwebsite\Excel\Concerns\WithColumnFormatting;
use PhpOffice\PhpSpreadsheet\Style\NumberFormat;

class MasterJobsExport implements FromCollection, WithHeadings, WithColumnFormatting
{
    public function collection()
    {
        $data = DB::table('jobs as j')
            ->leftJoin('users as u', 'j.transporter_id', '=', 'u.id')
            ->leftJoin('states as s', 'u.states', '=', 's.id')

            ->leftJoin('applyjobs as a', 'j.id', '=', 'a.job_id')
            ->leftJoin('users as d', 'a.driver_id', '=', 'd.id')

            ->leftJoin('get_job as g', function ($join) {
                $join->on('g.job_id', '=', 'j.id')
                     ->on('g.driver_id', '=', 'd.id');
            })

            ->leftJoin('payments as pd', function ($join) {
                $join->on('pd.user_id', '=', 'd.id')
                     ->where('pd.payment_type', '=', 'subscription')
                     ->where('pd.payment_status', '=', 'captured');
            })

            ->leftJoin('payments as pt', function ($join) {
                $join->on('pt.user_id', '=', 'u.id')
                     ->where('pt.payment_type', '=', 'subscription')
                     ->where('pt.payment_status', '=', 'captured');
            })

            ->leftJoin('call_logs_transporter as clt', function ($join) {
                $join->on('clt.job_id', '=', 'j.id')
                     ->on('clt.driver_id', '=', 'd.id')
                     ->on('clt.transporter_id', '=', 'j.transporter_id');
            })

            ->orderByDesc('j.id')
            ->orderBy('d.name')
            ->select([
                'j.job_id as job_id',
                'j.job_title',
                'j.job_location',
                'j.Required_Experience',
                'j.Salary_Range',
                'j.Type_of_License',
                'j.Preferred_Skills',                
                'j.Job_Description',
                'j.vehicle_type',
                'j.number_of_drivers_required',
                'j.created_at as job_posted_date',
                'j.application_deadline',
                'j.status',
                'j.active_inactive',

                'u.unique_id as transporter_code',
                'u.name as transporter_name',
                'u.mobile as transporter_mobile',
                's.name as transporter_state',

                'pt.created_at as transporter_subscription_date',

                'd.unique_id as driver_TMID',
                'd.created_at as driver_registration',
                'd.name as driver_name',
                'd.mobile as driver_mobile',

                'g.status as application_status',
                'pd.created_at as driver_subscription_date',

                DB::raw('COALESCE(clt.call_count, 0) as call_count')
            ])
            ->get();

        // Transform dates and job status
        $data->transform(function ($j) {
            $j->job_posted_date = $j->job_posted_date
                ? Date::stringToExcel(date('Y-m-d', strtotime($j->job_posted_date)))
                : null;

            $j->application_deadline = $j->application_deadline
                ? Date::stringToExcel(date('Y-m-d', strtotime($j->application_deadline)))
                : null;

            $j->transporter_subscription_date = $j->transporter_subscription_date
                ? Date::stringToExcel(date('Y-m-d', strtotime($j->transporter_subscription_date)))
                : null;

            $j->driver_registration = $j->driver_registration
                ? Date::stringToExcel(date('Y-m-d', strtotime($j->driver_registration)))
                : null;

            $j->driver_subscription_date = $j->driver_subscription_date
                ? Date::stringToExcel(date('Y-m-d', strtotime($j->driver_subscription_date)))
                : null;

            // ✅ Updated logic for job status display
            $j->status = $j->status == 1 ? 'Verified' : 'Pending';

            $j->active_inactive = $j->active_inactive == 1 ? 'Active' : 'Inactive';

            return $j;
        });

        return $data;
    }

    public function headings(): array
    {
        return [
            'Job ID',
            'Job Title',
            'Job Location',
            'Required Experience',
            'Salary Range',
            'Type of License',
            'Preferred Skills',            
            'Job Description',
            'Vehicle Type',
            'Number of Drivers Required',
            'Job Posted Date',
            'Application Deadline',
            'Job Status',
            'Active/Inactive',

            'Transporter TMID',
            'Transporter Name',
            'Transporter Mobile',
            'Transporter State',
            'Transporter Subscription Date',

            'Driver TMID',
            'Driver Registration Date',
            'Driver Name',
            'Driver Mobile',

            'Application Status (get_job)',
            'Driver Subscription Date',

            'Call Count',
        ];
    }

    public function columnFormats(): array
    {
        return [
            'K' => NumberFormat::FORMAT_DATE_DDMMYYYY, // Job Posted Date
            'L' => NumberFormat::FORMAT_DATE_DDMMYYYY, // Application Deadline
            'S' => NumberFormat::FORMAT_DATE_DDMMYYYY, // Transporter Subscription Date
            'U' => NumberFormat::FORMAT_DATE_DDMMYYYY, // Driver Registration Date
            'Y' => NumberFormat::FORMAT_DATE_DDMMYYYY, // Driver Subscription Date
        ];
    }
}
