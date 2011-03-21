/******************************************************************************
 * 
 * Copyright 2010-2011 Duane Merrill
 * 
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 * 
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License. 
 * 
 * For more information, see our Google Code project site: 
 * http://code.google.com/p/back40computing/
 * 
 * Thanks!
 * 
 ******************************************************************************/

/******************************************************************************
 * Tile-processing functionality for downsweep scan kernels
 ******************************************************************************/

#pragma once

#include <b40c/util/io/modified_load.cuh>
#include <b40c/util/io/modified_store.cuh>
#include <b40c/util/io/load_tile.cuh>
#include <b40c/util/io/store_tile.cuh>

#include <b40c/util/scan/cooperative_scan.cuh>

namespace b40c {
namespace scan {


/**
 * Derivation of KernelConfig that encapsulates downsweep scan tile-processing
 * routines state and routines
 */
template <typename KernelConfig>
struct DownsweepCta : KernelConfig
{
	//---------------------------------------------------------------------
	// Typedefs
	//---------------------------------------------------------------------

	typedef typename KernelConfig::T T;
	typedef typename KernelConfig::SizeT SizeT;
	typedef typename KernelConfig::SrtsDetails SrtsDetails;

	//---------------------------------------------------------------------
	// Members
	//---------------------------------------------------------------------

	// Running partial accumulated by the CTA over its tile-processing
	// lifetime (managed in each raking thread)
	T carry;

	// Input and output device pointers
	T *d_in;
	T *d_out;

	// Operational details for SRTS scan grid
	SrtsDetails srts_details;


	//---------------------------------------------------------------------
	// Methods
	//---------------------------------------------------------------------

	/**
	 * Constructor
	 */
	__device__ __forceinline__ DownsweepCta(
		SrtsDetails srts_details,
		T *d_in,
		T *d_out,
		T spine_partial = KernelConfig::Identity()) :

			srts_details(srts_details),
			d_in(d_in),
			d_out(d_out),
			carry(spine_partial) {}			// Seed carry with spine partial


	/**
	 * Process a single tile
	 */
	template <bool FULL_TILE>
	__device__ __forceinline__ void ProcessTile(
		SizeT cta_offset,
		SizeT out_of_bounds)
	{
		// Tile of scan elements
		T data[KernelConfig::LOADS_PER_TILE][KernelConfig::LOAD_VEC_SIZE];

		// Load tile
		util::io::LoadTile<
			KernelConfig::LOG_LOADS_PER_TILE,
			KernelConfig::LOG_LOAD_VEC_SIZE,
			KernelConfig::THREADS,
			KernelConfig::READ_MODIFIER,
			FULL_TILE>::Invoke(data, d_in, cta_offset, out_of_bounds);

		// Scan tile with carry update in raking threads
		util::scan::CooperativeTileScan<
			SrtsDetails,
			KernelConfig::LOAD_VEC_SIZE,
			KernelConfig::EXCLUSIVE,
			KernelConfig::BinaryOp>::ScanTileWithCarry(srts_details, data, carry);

		// Store tile
		util::io::StoreTile<
			KernelConfig::LOG_LOADS_PER_TILE,
			KernelConfig::LOG_LOAD_VEC_SIZE,
			KernelConfig::THREADS,
			KernelConfig::WRITE_MODIFIER,
			FULL_TILE>::Invoke(data, d_out, cta_offset, out_of_bounds);
	}
};



} // namespace scan
} // namespace b40c

