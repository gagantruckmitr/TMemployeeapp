<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class CreateDriverVideoProgressTable extends Migration
{
    public function up()
    {
        Schema::create('driver_video_progress', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('driver_id');
            $table->unsignedBigInteger('video_id');
            $table->boolean('is_completed')->default(false);
            $table->timestamps();

            // $table->foreign('driver_id')->references('id')->on('drivers')->onDelete('cascade');
            // $table->foreign('video_id')->references('id')->on('videos')->onDelete('cascade');
        });
    }

    public function down()
    {
        Schema::dropIfExists('driver_video_progress');
    }
}
