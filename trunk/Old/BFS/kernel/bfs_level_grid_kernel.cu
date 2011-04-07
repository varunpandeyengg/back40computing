/******************************************************************************
 * 
 * Copyright 2010 Duane Merrill
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
 * 
 * BFS-LEVEL: A level-syncronized breadth-first-search kernel.  (One level per 
 * launch.)  
 * 
 ******************************************************************************/

#pragma once

#include <bfs_kernel_common.cu>

namespace b40c {
namespace bfs {


/******************************************************************************
 * BFS-LEVEL Granularity Configuration 
 ******************************************************************************/

//  CTA size in threads
#define B40C_BFS_LEVEL_SM20_LOG_CTA_THREADS(strategy)				((strategy == EXPAND_CONTRACT) ? 7 : 7)				// 128 threads on GF100		 
#define B40C_BFS_LEVEL_SM12_LOG_CTA_THREADS(strategy)				((strategy == EXPAND_CONTRACT) ? 8 : 8)		 		// 128 threads on GT200
#define B40C_BFS_LEVEL_SM10_LOG_CTA_THREADS(strategy)				((strategy == EXPAND_CONTRACT) ? 8 : 8)				// 128 threads on G80
#define B40C_BFS_LEVEL_LOG_CTA_THREADS(sm_version, strategy)		((sm_version >= 200) ? B40C_BFS_LEVEL_SM20_LOG_CTA_THREADS(strategy) : 	\
																	 (sm_version >= 120) ? B40C_BFS_LEVEL_SM12_LOG_CTA_THREADS(strategy) : 	\
																					   B40C_BFS_LEVEL_SM10_LOG_CTA_THREADS(strategy))		

// Target CTA occupancy.  Params: SM sm_version
#define B40C_BFS_LEVEL_SM20_OCCUPANCY()							(8)				// 8 threadblocks on GF100
#define B40C_BFS_LEVEL_SM12_OCCUPANCY()							(1)				// 1 threadblocks on GT200
#define B40C_BFS_LEVEL_SM10_OCCUPANCY()							(1)				// 1 threadblocks on G80
#define B40C_BFS_LEVEL_OCCUPANCY(sm_version)					((sm_version >= 200) ? B40C_BFS_LEVEL_SM20_OCCUPANCY() : 	\
																 (sm_version >= 120) ? B40C_BFS_LEVEL_SM12_OCCUPANCY() : 	\
																					   B40C_BFS_LEVEL_SM10_OCCUPANCY())		


// Vector size of load. Params: SM sm_version, algorithm				
// (N.B.: currently only vec-1 for EXPAND_CONTRACT, up to vec-4 for CONTRACT_EXPAND)  
#define B40C_BFS_LEVEL_SM20_LOG_LOAD_VEC_SIZE(strategy)			((strategy == EXPAND_CONTRACT) ? 0 : 0)		 
#define B40C_BFS_LEVEL_SM12_LOG_LOAD_VEC_SIZE(strategy)			((strategy == EXPAND_CONTRACT) ? 0 : 1)		 
#define B40C_BFS_LEVEL_SM10_LOG_LOAD_VEC_SIZE(strategy)			((strategy == EXPAND_CONTRACT) ? 0 : 1)		
#define B40C_BFS_LEVEL_LOG_LOAD_VEC_SIZE(sm_version, strategy)		((sm_version >= 200) ? B40C_BFS_LEVEL_SM20_LOG_LOAD_VEC_SIZE(strategy) : 	\
																 (sm_version >= 120) ? B40C_BFS_LEVEL_SM12_LOG_LOAD_VEC_SIZE(strategy) : 	\
																					   B40C_BFS_LEVEL_SM10_LOG_LOAD_VEC_SIZE(strategy))		


// Number of raking threads.  Params: SM sm_version, strategy			
// (N.B: currently supported up to 1 warp)
#define B40C_BFS_LEVEL_SM20_LOG_RAKING_THREADS(sm_version)					(B40C_LOG_WARP_THREADS(sm_version) + 0)		// 1 raking warps on GF100
#define B40C_BFS_LEVEL_SM12_LOG_RAKING_THREADS(sm_version)					(B40C_LOG_WARP_THREADS(sm_version) + 0)		// 1 raking warps on GT200
#define B40C_BFS_LEVEL_SM10_LOG_RAKING_THREADS(sm_version)					(B40C_LOG_WARP_THREADS(sm_version) + 0)		// 1 raking warps on G80
#define B40C_BFS_LEVEL_LOG_RAKING_THREADS(sm_version, strategy)		((sm_version >= 200) ? B40C_BFS_LEVEL_SM20_LOG_RAKING_THREADS(sm_version) : 	\
																	 (sm_version >= 120) ? B40C_BFS_LEVEL_SM12_LOG_RAKING_THREADS(sm_version) : 	\
																					   B40C_BFS_LEVEL_SM10_LOG_RAKING_THREADS(sm_version))

// Size of sractch space (in bytes).  Params: SM sm_version, strategy
#define B40C_BFS_LEVEL_SM20_SCRATCH_SPACE(strategy)					(45 * 1024 / B40C_BFS_LEVEL_SM20_OCCUPANCY()) 
#define B40C_BFS_LEVEL_SM12_SCRATCH_SPACE(strategy)					(15 * 1024 / B40C_BFS_LEVEL_SM12_OCCUPANCY())
#define B40C_BFS_LEVEL_SM10_SCRATCH_SPACE(strategy)					(7  * 1024 / B40C_BFS_LEVEL_SM10_OCCUPANCY())
#define B40C_BFS_LEVEL_SCRATCH_SPACE(sm_version, strategy)			((sm_version >= 200) ? B40C_BFS_LEVEL_SM20_SCRATCH_SPACE(strategy) : 	\
																	 (sm_version >= 120) ? B40C_BFS_LEVEL_SM12_SCRATCH_SPACE(strategy) : 	\
																					   B40C_BFS_LEVEL_SM10_SCRATCH_SPACE(strategy))		

// Number of elements per tile.  Params: SM sm_version, strategy
#define B40C_BFS_LEVEL_LOG_TILE_ELEMENTS(sm_version, strategy)		(B40C_BFS_LEVEL_LOG_CTA_THREADS(sm_version, strategy) + B40C_BFS_LEVEL_LOG_LOAD_VEC_SIZE(sm_version, strategy))

// Number of elements per subtile.  Params: strategy  
#define B40C_BFS_LEVEL_LOG_SUBTILE_ELEMENTS(strategy)				((strategy == EXPAND_CONTRACT) ? 5 : 6)		// 64 for CONTRACT_EXPAND, 32 for EXPAND_CONTRACT


/******************************************************************************
 * Kernel routines
 ******************************************************************************/

/**
 * 
 * A single-grid breadth-first-search kernel.  (BFS-LEVEL)
 * 
 * Marks each node with its distance from the given "source" node.  (I.e., 
 * nodes are marked with the iteration at which they were "discovered").
 *     
 * A BFS search iteratively expands outwards from the given source node.  At 
 * each iteration, the algorithm discovers unvisited nodes that are adjacent 
 * to the nodes discovered by the previous iteration.  The first iteration 
 * discovers the source node. 
 * 
 * All iterations are performed by a single kernel-launch.  This is 
 * made possible by software global-barriers across threadblocks.  
 * 
 * The algorithm strategy is either:
 *   (a) Contract-then-expand
 *   (b) Expand-then-contract
 * For more details, see the enum type BfsStrategy
 *   
 *
 */
template <
	typename VertexId,
	int STRATEGY>			// Should be of type "BfsStrategy": NVBUGS 768132
__launch_bounds__ (
	1 << B40C_BFS_LEVEL_LOG_CTA_THREADS(__B40C_CUDA_ARCH__, STRATEGY),
	B40C_BFS_LEVEL_OCCUPANCY(__B40C_CUDA_ARCH__))
__global__ void BfsLevelGridKernel(
	VertexId src,										// Source node for the first iteration
	unsigned char *d_collision_cache,
	VertexId *d_in_queue,								// Queue of node-IDs to consume
	VertexId *d_out_queue,								// Queue of node-IDs to produce
	VertexId *d_column_indices,						// CSR column indices
	VertexId *d_row_offsets,							// CSR row offsets
	VertexId *d_source_path,							// Distance from the source node (initialized to -1) (per-node)
	int *d_queue_lengths, 								// Rotating 4-element array of atomic counters indicating sizes of the incoming and outgoing frontier queues
	VertexId iteration) 								// Current BFS iteration
{
	const int LOG_CTA_THREADS			= B40C_BFS_LEVEL_LOG_CTA_THREADS(__B40C_CUDA_ARCH__, STRATEGY);
	const int CTA_THREADS				= 1 << LOG_CTA_THREADS;
	
	const int TILE_ELEMENTS 			= 1 << B40C_BFS_LEVEL_LOG_TILE_ELEMENTS(__B40C_CUDA_ARCH__, STRATEGY);

	const int LOG_SUBTILE_ELEMENTS		= B40C_BFS_LEVEL_LOG_SUBTILE_ELEMENTS(STRATEGY);
	const int SUBTILE_ELEMENTS			= 1 << LOG_SUBTILE_ELEMENTS;		
	
	const int SCRATCH_SPACE				= B40C_BFS_LEVEL_SCRATCH_SPACE(__B40C_CUDA_ARCH__, STRATEGY) / sizeof(VertexId);
	const int LOAD_VEC_SIZE				= 1 << B40C_BFS_LEVEL_LOG_LOAD_VEC_SIZE(__B40C_CUDA_ARCH__, STRATEGY);
	const int RAKING_THREADS			= 1 << B40C_BFS_LEVEL_LOG_RAKING_THREADS(__B40C_CUDA_ARCH__, STRATEGY);
	
	// Number of scan partials for a tile
	const int LOG_SCAN_PARTIALS 		= LOG_CTA_THREADS;			// One partial per thread
	const int SCAN_PARTIALS				= 1 << LOG_SCAN_PARTIALS;

	// Number of scan partials per raking segment
	const int LOG_PARTIALS_PER_SEG		= LOG_SCAN_PARTIALS - B40C_LOG_WARP_THREADS(__B40C_CUDA_ARCH__);
	const int PARTIALS_PER_SEG			= 1 << LOG_PARTIALS_PER_SEG;
	
	// Number of scan partials per scratch_pool row
	const int LOG_PARTIALS_PER_ROW		= B40C_MAX(B40C_LOG_MEM_BANKS(__B40C_CUDA_ARCH__), LOG_PARTIALS_PER_SEG); 	// Floor of MEM_BANKS partials per row
	const int PARTIALS_PER_ROW			= 1 << LOG_PARTIALS_PER_ROW;
	const int PADDED_PARTIALS_PER_ROW 	= PARTIALS_PER_ROW + 1;
	const int SCAN_ROWS 				= SCAN_PARTIALS / PARTIALS_PER_ROW;		// Number of scratch_pool rows for scan 
	
	// Number of raking segments per scratch_pool row
	const int LOG_SEGS_PER_ROW 			= LOG_PARTIALS_PER_ROW - LOG_PARTIALS_PER_SEG;		
	const int SEGS_PER_ROW				= 1 << LOG_SEGS_PER_ROW;

	// Figure out how big our multipurpose scratch_pool allocation should be (in 128-bit int4s)
	const int SCAN_BYTES				= SCAN_ROWS * PADDED_PARTIALS_PER_ROW * sizeof(int);
	const int SCRATCH_BYTES				= SCRATCH_SPACE * sizeof(VertexId);
	const int SHARED_BYTES 				= B40C_MAX(SCAN_BYTES, SCRATCH_BYTES);
	const int SHARED_INT4S				= (SHARED_BYTES + sizeof(int4) - 1) / sizeof(int4);

	// Cache-modifiers
	const util::io::ld::CacheModifier QUEUE_LD_MODIFIER						= util::io::ld::cg;
	const util::io::st::CacheModifier QUEUE_ST_MODIFIER 					= util::io::st::cg;
	const util::io::ld::CacheModifier COLUMN_INDICES_MODIFIER				= util::io::ld::cg;
	const util::io::ld::CacheModifier ROW_OFFSETS_MODIFIER					= util::io::ld::ca;
	const util::io::ld::CacheModifier MISALIGNED_ROW_OFFSETS_MODIFIER		= util::io::ld::ca;
	
	util::SuppressUnusedConstantWarning(CTA_THREADS);
	util::SuppressUnusedConstantWarning(LOAD_VEC_SIZE);
	util::SuppressUnusedConstantWarning(PARTIALS_PER_SEG);
	util::SuppressUnusedConstantWarning(QUEUE_LD_MODIFIER);
	util::SuppressUnusedConstantWarning(QUEUE_ST_MODIFIER);
	util::SuppressUnusedConstantWarning(COLUMN_INDICES_MODIFIER);
	util::SuppressUnusedConstantWarning(ROW_OFFSETS_MODIFIER);
	util::SuppressUnusedConstantWarning(MISALIGNED_ROW_OFFSETS_MODIFIER);
	
	
	__shared__ int4 aligned_smem_pool[SHARED_INT4S];	// Smem for: (i) raking prefix sum; and (ii) hashing/compaction scratch space
	__shared__ int warpscan[2][B40C_WARP_THREADS(__B40C_CUDA_ARCH__)];		// Smem for cappping off the local prefix sum
	__shared__ int s_enqueue_offset;					// Current tile's offset into the output queue for the next iteration 

	int* 		scan_pool = reinterpret_cast<int*>(aligned_smem_pool);				// The smem pool for (i) above
	VertexId* 	scratch_pool = reinterpret_cast<VertexId*>(aligned_smem_pool);		// The smem pool for (ii) above
	
	__shared__ int s_num_incoming_nodes;
	__shared__ int s_cta_offset;			// Offset in the incoming frontier queue for this CTA to begin raking its tiles
	__shared__ int s_cta_extra_elements;	// Number of elements in a last, partially-full tile (needing guarded loads)   
	__shared__ int s_cta_out_of_bounds;		// The offset in the incoming frontier for this CTA to stop raking full tiles


	
	//
	// Initialize structures
	//

	// Raking threads determine their scan_pool segment to sequentially rake for smem reduction/scan
	int *raking_segment;						 
	if (threadIdx.x < RAKING_THREADS) {

		int row = threadIdx.x >> LOG_SEGS_PER_ROW;
		int col = (threadIdx.x & (SEGS_PER_ROW - 1)) << LOG_PARTIALS_PER_SEG;
		raking_segment = scan_pool + (row * PADDED_PARTIALS_PER_ROW) + col; 
	}
	
	// Set identity into first half of warpscan 
	if (threadIdx.x < B40C_WARP_THREADS(__B40C_CUDA_ARCH__)) {
		warpscan[0][threadIdx.x] = 0;
	}
	
	// Determine which scan_pool cell to place my partial reduction into
	int row = threadIdx.x >> LOG_PARTIALS_PER_ROW; 
	int col = threadIdx.x & (PARTIALS_PER_ROW - 1); 
	int *base_partial = scan_pool + (row * PADDED_PARTIALS_PER_ROW) + col;
	
	if (threadIdx.x == 0) {
	
		if (iteration == 0) { 

			// First iteration: process the source node specified in the formal parameters
			s_cta_offset = 0;
			s_cta_out_of_bounds = 0;
			
			if (blockIdx.x == 0) {
				
				// First CTA resets global atomic counter for future outgoing counter
				int future_queue_length_idx = (iteration + 2) & 0x3; 	// Index of the future outgoing queue length (must reset for the next iteration) 
				d_queue_lengths[future_queue_length_idx] = 0;
	
				// Only the first CTA does any work (so enqueue it, and reset outgoing queue length) 
				s_cta_extra_elements = 1;
				d_in_queue[0] = src;
				d_queue_lengths[1] = 0;
				
				// Expand-contract algorithm requires setting source to already-discovered
				if (STRATEGY == EXPAND_CONTRACT) {
					d_source_path[src] = 0;
				}
				
			} else {
	
				// No work for all other CTAs
				s_cta_extra_elements = 0;
			}
			s_num_incoming_nodes = 1;
			
		} else {
			
			// Calculate our CTA's work range for a subsequent BFS iteration

			// First CTA resets global atomic counter for future outgoing counter
			if (blockIdx.x == 0) {
				int future_queue_length_idx = (iteration + 2) & 0x3; 	// Index of the future outgoing queue length (must reset for the next iteration) 
				d_queue_lengths[future_queue_length_idx] = 0;
			}

			// Load the size of the incoming frontier queue
			int num_incoming_nodes;
			int incoming_queue_length_idx = (iteration + 0) & 0x3;	// Index of incoming queue length
			util::io::ModifiedLoad<util::io::ld::cg>::Ld(num_incoming_nodes, d_queue_lengths + incoming_queue_length_idx);
	
			//
			// Although work is done in "tile"-sized blocks, work is assigned 
			// across CTAs in smaller "subtile"-sized blocks for better 
			// load-balancing on small problems.  We follow our standard pattern 
			// of spreading the subtiles over p CTAs by giving each CTA a batch of 
			// either k or (k + 1) subtiles.  (And the last CTA must account for 
			// its last subtile likely only being partially-full.)
			//
			
			int total_subtiles 			= (num_incoming_nodes + SUBTILE_ELEMENTS - 1) >> LOG_SUBTILE_ELEMENTS;	// round up
			int subtiles_per_cta 		= total_subtiles / gridDim.x;										// round down for the ks
			int extra_subtiles 			= total_subtiles - (subtiles_per_cta * gridDim.x);					// the +1s 
	
			// Compute number of elements and offset at which to start tile processing
			int cta_elements, cta_offset;
			if (blockIdx.x < extra_subtiles) {
				// The first extra_subtiles-CTAs get k+1 subtiles
				cta_elements = (subtiles_per_cta + 1) << LOG_SUBTILE_ELEMENTS;
				cta_offset = cta_elements * blockIdx.x;
			} else if (blockIdx.x < total_subtiles) {
				// The others get k subtiles
				cta_elements = subtiles_per_cta << LOG_SUBTILE_ELEMENTS;
				cta_offset = (cta_elements * blockIdx.x) + (extra_subtiles << LOG_SUBTILE_ELEMENTS);
			} else {
				// Problem small enough that some CTAs don't even a single subtile
				cta_elements = 0;
				cta_offset = 0;
			}
			
			// Compute (i) TILE aligned limit for tile-processing (oob), 
			// and (ii) how many extra guarded-load elements to process 
			// afterward (always less than a full TILE) 
			int cta_out_of_bounds = cta_offset + cta_elements;
			int cta_extra_elements;
			
			if (cta_out_of_bounds > num_incoming_nodes) {
				// The last CTA rounded its last subtile past the end of the queue
				cta_out_of_bounds -= SUBTILE_ELEMENTS;
				cta_elements -= SUBTILE_ELEMENTS;
				cta_extra_elements = (num_incoming_nodes & (SUBTILE_ELEMENTS - 1)) +		// The delta from the previous SUBTILE alignment and the end of the queue 
					(cta_elements & (TILE_ELEMENTS - 1));									// The delta from the previous TILE alignment 
			} else {
				cta_extra_elements = cta_elements & (TILE_ELEMENTS - 1);				// The delta from the previous TILE alignment
			}

			// Store results for the rest of the CTA
			s_cta_offset = cta_offset;
			s_cta_out_of_bounds = cta_out_of_bounds;
			s_cta_extra_elements = cta_extra_elements;
			s_num_incoming_nodes = num_incoming_nodes;
		}
	}
	
	__syncthreads();

	// Index of the outgoing queue length
	int outgoing_queue_length_idx = (iteration + 1) & 0x3; 				

	// Perform a pass through the incoming frontier queue
	BfsIteration<(BfsStrategy) STRATEGY, VertexId, CTA_THREADS, TILE_ELEMENTS, PARTIALS_PER_SEG, SCRATCH_SPACE,
			LOAD_VEC_SIZE, QUEUE_LD_MODIFIER, QUEUE_ST_MODIFIER, COLUMN_INDICES_MODIFIER,
			ROW_OFFSETS_MODIFIER, MISALIGNED_ROW_OFFSETS_MODIFIER>(
		iteration, s_num_incoming_nodes, scratch_pool, base_partial, raking_segment, warpscan,
		d_collision_cache, d_in_queue, d_out_queue, d_column_indices, d_row_offsets, d_source_path, d_queue_lengths + outgoing_queue_length_idx,
		s_enqueue_offset, s_cta_offset, s_cta_extra_elements, s_cta_out_of_bounds);
} 


} // namespace bfs
} // b40c namespace


