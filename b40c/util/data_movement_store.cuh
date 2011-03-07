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
 * Kernel utilities for storing types through global memory with cache modifiers
 ******************************************************************************/

#pragma once

#include <b40c/util/cuda_properties.cuh>
#include <b40c/util/vector_types.cuh>

namespace b40c {
namespace util {


/**
 * Enumeration of data movement cache modifiers.
 */
namespace st {
enum CacheModifier {
	NONE,			// default (currently CA)
	CG,				// cache global
	WB,				// write back all levels
	CS, 			// cache streaming

	LIMIT
};
} // namespace st
	

/**
 * Routines for modified stores through cache.  We use structs specialized by value 
 * type and cache-modifier to implement store operations
 */
template <typename T, st::CacheModifier CACHE_MODIFIER> struct ModifiedStore;

#if __CUDA_ARCH__ >= 200


	/**
	 * Defines specialized store ops for only the base type 
	 */

	#define B40C_DEFINE_BASE_GLOBAL_STORE(base_type, ptx_type, reg_mod)																								\
		template <> struct ModifiedStore<base_type, st::NONE> {																											\
			__device__ __forceinline__ static void St(const base_type &val, base_type* d_ptr, size_t offset) {														\
				d_ptr[offset] = val;																																\
			}																																						\
		};																																							\
		template <> struct ModifiedStore<base_type, st::CG> {																											\
			__device__ __forceinline__ static void St(const base_type &val, base_type* d_ptr, size_t offset) {														\
				asm("st.global.cg."#ptx_type" [%0], %1;" : : _B40C_ASM_PTR_(d_ptr + offset), #reg_mod(val));														\
			}																																						\
		};																																							\
		template <> struct ModifiedStore<base_type, st::CS> {																											\
			__device__ __forceinline__ static void St(const base_type &val, base_type* d_ptr, size_t offset) {														\
				asm("st.global.cs."#ptx_type" [%0], %1;" : : _B40C_ASM_PTR_(d_ptr + offset), #reg_mod(val));														\
			}																																						\
		};																																							\
		template <> struct ModifiedStore<base_type, st::WB> {																											\
			__device__ __forceinline__ static void St(const base_type &val, base_type* d_ptr, size_t offset) {														\
				asm("st.global.wb."#ptx_type" [%0], %1;" : : _B40C_ASM_PTR_(d_ptr + offset), #reg_mod(val));														\
			}																																						\
		};																																								


	/**
	 * Defines specialized store ops for both the base type and for its derivative vector types
	 */
	#define B40C_DEFINE_GLOBAL_STORE(base_type, dest_type, short_type, ptx_type, reg_mod)																			\
		template <> struct ModifiedStore<base_type, st::NONE> {																											\
			__device__ __forceinline__ static void St(const base_type &val, base_type* d_ptr, size_t offset) {														\
				d_ptr[offset] = val;																																\
			}																																						\
		};																																							\
		template <> struct ModifiedStore<base_type, st::CG> {																											\
			__device__ __forceinline__ static void St(const base_type &val, base_type* d_ptr, size_t offset) {														\
				asm("st.global.cg."#ptx_type" [%0], %1;" : : _B40C_ASM_PTR_(d_ptr + offset), #reg_mod(val));														\
			}																																						\
		};																																							\
		template <> struct ModifiedStore<base_type, st::CS> {																											\
			__device__ __forceinline__ static void St(const base_type &val, base_type* d_ptr, size_t offset) {														\
				asm("st.global.cs."#ptx_type" [%0], %1;" : : _B40C_ASM_PTR_(d_ptr + offset), #reg_mod(val));														\
			}																																						\
		};																																							\
		template <> struct ModifiedStore<base_type, st::WB> {																											\
			__device__ __forceinline__ static void St(const base_type &val, base_type* d_ptr, size_t offset) {														\
				asm("st.global.wb."#ptx_type" [%0], %1;" : : _B40C_ASM_PTR_(d_ptr + offset), #reg_mod(val));														\
			}																																						\
		};																																							\
		template <> struct ModifiedStore<short_type##1, st::NONE> {																										\
			__device__ __forceinline__ static void St(const short_type##1 &val, short_type##1* d_ptr, size_t offset) {												\
				d_ptr[offset] = val;																																\
			}																																						\
		};																																							\
		template <> struct ModifiedStore<short_type##1, st::CG> {																										\
			__device__ __forceinline__ static void St(const short_type##1 &val, short_type##1* d_ptr, size_t offset) {												\
				asm("st.global.cg."#ptx_type" [%0], %1;" : : _B40C_ASM_PTR_(d_ptr + offset), #reg_mod(val.x));														\
			}																																						\
		};																																							\
		template <> struct ModifiedStore<short_type##1, st::CS> {																										\
			__device__ __forceinline__ static void St(const short_type##1 &val, short_type##1* d_ptr, size_t offset) {												\
				asm("st.global.cs."#ptx_type" [%0], %1;" : : _B40C_ASM_PTR_(d_ptr + offset), #reg_mod(val.x));														\
			}																																						\
		};																																							\
		template <> struct ModifiedStore<short_type##1, st::WB> {																										\
			__device__ __forceinline__ static void St(const short_type##1 &val, short_type##1* d_ptr, size_t offset) {												\
				asm("st.global.wb."#ptx_type" [%0], %1;" : : _B40C_ASM_PTR_(d_ptr + offset), #reg_mod(val.x));														\
			}																																						\
		};																																							\
		template <> struct ModifiedStore<short_type##2, st::NONE> {																										\
			__device__ __forceinline__ static void St(const short_type##2 &val, short_type##2* d_ptr, size_t offset) {												\
				d_ptr[offset] = val;																																\
			}																																						\
		};																																							\
		template <> struct ModifiedStore<short_type##2, st::CG> {																										\
			__device__ __forceinline__ static void St(const short_type##2 &val, short_type##2* d_ptr, size_t offset) {												\
				asm("st.global.cg.v2."#ptx_type" [%0], {%1, %2};" : :  _B40C_ASM_PTR_(d_ptr + offset), #reg_mod(val.x), #reg_mod(val.y));							\
			}																																						\
		};																																							\
		template <> struct ModifiedStore<short_type##2, st::CS> {																										\
			__device__ __forceinline__ static void St(const short_type##2 &val, short_type##2* d_ptr, size_t offset) {												\
				asm("st.global.cs.v2."#ptx_type" [%0], {%1, %2};" : :  _B40C_ASM_PTR_(d_ptr + offset), #reg_mod(val.x), #reg_mod(val.y));							\
			}																																						\
		};																																							\
		template <> struct ModifiedStore<short_type##2, st::WB> {																										\
			__device__ __forceinline__ static void St(const short_type##2 &val, short_type##2* d_ptr, size_t offset) {												\
				asm("st.global.wb.v2."#ptx_type" [%0], {%1, %2};" : :  _B40C_ASM_PTR_(d_ptr + offset), #reg_mod(val.x), #reg_mod(val.y));							\
			}																																						\
		};

	/**
	 * Defines specialized store ops for the vec-4 derivative vector types
	 */
	#define B40C_DEFINE_GLOBAL_QUAD_STORE(base_type, dest_type, short_type, ptx_type, reg_mod)																							\
		template <> struct ModifiedStore<short_type##4, st::NONE> {																															\
			__device__ __forceinline__ static void St(const short_type##4 &val, short_type##4* d_ptr, size_t offset) {																	\
				d_ptr[offset] = val;																																					\
			}																																											\
		};																																												\
		template <> struct ModifiedStore<short_type##4, st::CG> {																															\
			__device__ __forceinline__ static void St(const short_type##4 &val, short_type##4* d_ptr, size_t offset) {																	\
				asm("st.global.cg.v4."#ptx_type"  [%0], {%1, %2, %3, %4};" : : _B40C_ASM_PTR_(d_ptr + offset), #reg_mod(val.x), #reg_mod(val.y), #reg_mod(val.z), #reg_mod(val.w));		\
			}																																											\
		};																																												\
		template <> struct ModifiedStore<short_type##4, st::CS> {																															\
			__device__ __forceinline__ static void St(const short_type##4 &val, short_type##4* d_ptr, size_t offset) {																	\
				asm("st.global.cs.v4."#ptx_type"  [%0], {%1, %2, %3, %4};" : : _B40C_ASM_PTR_(d_ptr + offset), #reg_mod(val.x), #reg_mod(val.y), #reg_mod(val.z), #reg_mod(val.w));		\
			}																																											\
		};																																												\
		template <> struct ModifiedStore<short_type##4, st::WB> {																															\
			__device__ __forceinline__ static void St(const short_type##4 &val, short_type##4* d_ptr, size_t offset) {																	\
				asm("st.global.wb.v4."#ptx_type"  [%0], {%1, %2, %3, %4};" : : _B40C_ASM_PTR_(d_ptr + offset), #reg_mod(val.x), #reg_mod(val.y), #reg_mod(val.z), #reg_mod(val.w));		\
			}																																											\
		};

	// Cache-modified stores for built-in structures
	B40C_DEFINE_GLOBAL_STORE(char, signed char, char, s8, r)
	B40C_DEFINE_GLOBAL_STORE(short, short, short, s16, r)
	B40C_DEFINE_GLOBAL_STORE(int, int, int, s32, r)
	B40C_DEFINE_GLOBAL_STORE(long, long, long, s64, l)
	B40C_DEFINE_GLOBAL_STORE(long long, long long, longlong, s64, l)
	B40C_DEFINE_GLOBAL_STORE(unsigned char, unsigned char, uchar, u8, r)
	B40C_DEFINE_GLOBAL_STORE(unsigned short, unsigned short, ushort, u16, r)
	B40C_DEFINE_GLOBAL_STORE(unsigned int, unsigned int, uint, u32, r)
	B40C_DEFINE_GLOBAL_STORE(unsigned long, unsigned long, ulong, u64, l)
	B40C_DEFINE_GLOBAL_STORE(unsigned long long, unsigned long long, ulonglong, u64, l)
	B40C_DEFINE_GLOBAL_STORE(float, float, float, f32, f)

	B40C_DEFINE_GLOBAL_QUAD_STORE(char, signed char, char, s8, r)
	B40C_DEFINE_GLOBAL_QUAD_STORE(short, short, short, s16, r)
	B40C_DEFINE_GLOBAL_QUAD_STORE(int, int, int, s32, r)
	B40C_DEFINE_GLOBAL_QUAD_STORE(long, long, long, s64, l)
	B40C_DEFINE_GLOBAL_QUAD_STORE(unsigned char, unsigned char, uchar, u8, r)
	B40C_DEFINE_GLOBAL_QUAD_STORE(unsigned short, unsigned short, ushort, u16, r)
	B40C_DEFINE_GLOBAL_QUAD_STORE(unsigned int, unsigned int, uint, u32, r)
	B40C_DEFINE_GLOBAL_QUAD_STORE(float, float, float, f32, f)

	B40C_DEFINE_BASE_GLOBAL_STORE(signed char, s8, r)			// only need to define base: char2,char4, etc already defined from char
	
	// Workaround for the fact that the assembler reports an error when attempting to 
	// make vector stores of doubles.

	B40C_DEFINE_BASE_GLOBAL_STORE(double, f64, d)

	template <st::CacheModifier CACHE_MODIFIER>
	struct ModifiedStore<double2, CACHE_MODIFIER> {
		__device__ __forceinline__ static void St(double2 &val, double2* d_ptr, size_t offset) {
			ModifiedStore<double, CACHE_MODIFIER>::St(val.x, reinterpret_cast<double*>(d_ptr + offset), 0);
			ModifiedStore<double, CACHE_MODIFIER>::St(val.y, reinterpret_cast<double*>(d_ptr + offset), 1);
		}
	};

	// Vec-4 loads for 64-bit types are implemented as two vec-2 loads

	template <st::CacheModifier CACHE_MODIFIER>
	struct ModifiedStore<double4, CACHE_MODIFIER> {
		__device__ __forceinline__ static void St(double4 &val, double4* d_ptr, size_t offset) {
			ModifiedStore<double2, CACHE_MODIFIER>::St(*reinterpret_cast<double2*>(&val.x), reinterpret_cast<double2*>(d_ptr + offset), 0);
			ModifiedStore<double2, CACHE_MODIFIER>::St(*reinterpret_cast<double2*>(&val.z), reinterpret_cast<double2*>(d_ptr + offset), 1);
		}																																							
	};																																								

	template <st::CacheModifier CACHE_MODIFIER>
	struct ModifiedStore<ulonglong4, CACHE_MODIFIER> {
		__device__ __forceinline__ static void St(ulonglong4 &val, ulonglong4* d_ptr, size_t offset) {
			ModifiedStore<ulonglong2, CACHE_MODIFIER>::St(*reinterpret_cast<ulonglong2*>(&val.x), reinterpret_cast<ulonglong2*>(d_ptr + offset), 0);
			ModifiedStore<ulonglong2, CACHE_MODIFIER>::St(*reinterpret_cast<ulonglong2*>(&val.z), reinterpret_cast<ulonglong2*>(d_ptr + offset), 1);
		}
	};

	template <st::CacheModifier CACHE_MODIFIER>
	struct ModifiedStore<longlong4, CACHE_MODIFIER> {
		__device__ __forceinline__ static void St(longlong4 &val, longlong4* d_ptr, size_t offset) {
			ModifiedStore<longlong2, CACHE_MODIFIER>::St(*reinterpret_cast<longlong2*>(&val.x), reinterpret_cast<longlong2*>(d_ptr + offset), 0);
			ModifiedStore<longlong2, CACHE_MODIFIER>::St(*reinterpret_cast<longlong2*>(&val.z), reinterpret_cast<longlong2*>(d_ptr + offset), 1);
		}																																							
	};
	

	#undef B40C_DEFINE_GLOBAL_QUAD_STORE
	#undef B40C_DEFINE_BASE_GLOBAL_STORE
	#undef B40C_DEFINE_GLOBAL_STORE

#else	// stores

	//
	// Nothing is cached in these architectures
	//
	
	// Store normally
	template <typename T, st::CacheModifier CACHE_MODIFIER> struct ModifiedStore
	{
		template <typename SizeT>
		__device__ __forceinline__ static void St(const T &val, T* d_ptr, SizeT offset) {
			d_ptr[offset] = val; 
		}
	};
	
#endif	// stores
	

/**
 * Store a tile of items
 */
template <
	typename T,
	typename SizeT,
	int LOG_STORES_PER_TILE, 
	int LOG_STORE_VEC_SIZE,
	int ACTIVE_THREADS,
	st::CacheModifier CACHE_MODIFIER,
	bool UNGUARDED_IO> 
		struct StoreTile;

/**
 * Store of a tile of items using unguarded stores 
 */
template <
	typename T,
	typename SizeT,
	int LOG_STORES_PER_TILE, 
	int LOG_STORE_VEC_SIZE,
	int ACTIVE_THREADS,
	st::CacheModifier CACHE_MODIFIER>
struct StoreTile <T, SizeT, LOG_STORES_PER_TILE, LOG_STORE_VEC_SIZE, ACTIVE_THREADS, CACHE_MODIFIER, true>
{
	static const int STORES_PER_TILE = 1 << LOG_STORES_PER_TILE;
	static const int STORE_VEC_SIZE = 1 << LOG_STORE_VEC_SIZE;
	
	// Aliased vector type
	typedef typename VecType<T, STORE_VEC_SIZE>::Type VectorType; 		

	// Iterate over stores
	template <int STORE, int __dummy = 0>
	struct Iterate 
	{
		static __device__ __forceinline__ void Invoke(
			VectorType vectors[], 
			VectorType *d_in_vectors) 
		{
			ModifiedStore<VectorType, CACHE_MODIFIER>::St(
				vectors[STORE], d_in_vectors, threadIdx.x);
			
			Iterate<STORE + 1>::Invoke(vectors, d_in_vectors + ACTIVE_THREADS);
		}
	};

	// Terminate
	template <int __dummy>
	struct Iterate<STORES_PER_TILE, __dummy> 
	{
		static __device__ __forceinline__ void Invoke(
			VectorType vectors[], VectorType *d_in_vectors) {} 
	};
	
	// Interface
	static __device__ __forceinline__ void Invoke(
		T data[][STORE_VEC_SIZE],
		T *d_in,
		SizeT cta_offset,
		const SizeT &out_of_bounds)
	{
		// Use an aliased pointer to keys array to perform built-in vector stores
		VectorType *vectors = (VectorType *) data;
		VectorType *d_in_vectors = (VectorType *) (d_in + cta_offset);
		
		Iterate<0>::Invoke(vectors, d_in_vectors);
	}
};
	

/**
 * Store of a tile of items using guarded stores 
 */
template <
	typename T,
	typename SizeT,
	int LOG_STORES_PER_TILE, 
	int LOG_STORE_VEC_SIZE,
	int ACTIVE_THREADS,
	st::CacheModifier CACHE_MODIFIER>
struct StoreTile <T, SizeT, LOG_STORES_PER_TILE, LOG_STORE_VEC_SIZE, ACTIVE_THREADS, CACHE_MODIFIER, false>
{
	static const int STORES_PER_TILE = 1 << LOG_STORES_PER_TILE;
	static const int STORE_VEC_SIZE = 1 << LOG_STORE_VEC_SIZE;

	// Iterate over vec-elements
	template <int STORE, int VEC>
	struct Iterate {
		static __device__ __forceinline__ void Invoke(
			T data[][STORE_VEC_SIZE],
			T *d_in,
			SizeT cta_offset,
			SizeT out_of_bounds)
		{
			SizeT thread_offset = cta_offset + VEC;

			if (thread_offset < out_of_bounds) {
				ModifiedStore<T, CACHE_MODIFIER>::St(data[STORE][VEC], d_in, thread_offset);
			}
			Iterate<STORE, VEC + 1>::Invoke(data, d_in, cta_offset, out_of_bounds);
		}
	};

	// Iterate over stores
	template <int STORE>
	struct Iterate<STORE, STORE_VEC_SIZE> {
		static __device__ __forceinline__ void Invoke(
			T data[][STORE_VEC_SIZE],
			T *d_in,
			SizeT cta_offset,
			SizeT out_of_bounds)
		{
			Iterate<STORE + 1, 0>::Invoke(
				data, d_in, cta_offset + (ACTIVE_THREADS << LOG_STORE_VEC_SIZE), out_of_bounds);
		}
	};
	
	// Terminate
	template <int VEC>
	struct Iterate<STORES_PER_TILE, VEC> {
		static __device__ __forceinline__ void Invoke(
			T data[][STORE_VEC_SIZE],
			T *d_in,
			SizeT cta_offset,
			SizeT out_of_bounds) {}
	};

	// Interface
	static __device__ __forceinline__ void Invoke(
		T data[][STORE_VEC_SIZE],
		T *d_in,
		SizeT cta_offset,
		SizeT out_of_bounds)
	{
		Iterate<0, 0>::Invoke(data, d_in, cta_offset + (threadIdx.x << LOG_STORE_VEC_SIZE), out_of_bounds);
	} 
};


/**
 * Empty default transform function (leaves non-in_bounds values as they were)
 */
template <typename T>
__device__ __forceinline__ void NopStoreTransform(T &val) {}


/**
 * Scatter a tile of data items using the corresponding tile of scatter_offsets
 */
template <
	typename T,
	typename SizeT,
	int LOADS_PER_TILE,
	int ACTIVE_THREADS,										// Active threads that will be loading
	st::CacheModifier CACHE_MODIFIER,							// Cache modifier (e.g., CA/CG/CS/NONE/etc.)
	bool UNGUARDED_IO,
	void Transform(T&) = NopStoreTransform<T> > 			// Assignment function to transform the loaded value (can be used assign default values for items deemed not in bounds)
struct Scatter
{
	// Iterate
	template <int LOAD, int TOTAL_LOADS>
	struct Iterate
	{
		static __device__ __forceinline__ void Invoke(
			T *dest,
			T src[LOADS_PER_TILE],
			SizeT scatter_offsets[LOADS_PER_TILE],
			const SizeT	&guarded_elements)
		{
			if (UNGUARDED_IO || ((ACTIVE_THREADS * LOAD) + threadIdx.x < guarded_elements)) {
				Transform(src[LOAD]);
				ModifiedStore<T, CACHE_MODIFIER>::St(src[LOAD], dest, scatter_offsets[LOAD]);
			}

			Iterate<LOAD + 1, TOTAL_LOADS>::Invoke(dest, src, scatter_offsets, guarded_elements);
		}
	};

	// Terminate
	template <int TOTAL_LOADS>
	struct Iterate<TOTAL_LOADS, TOTAL_LOADS>
	{
		static __device__ __forceinline__ void Invoke(
			T *dest,
			T src[LOADS_PER_TILE],
			SizeT scatter_offsets[LOADS_PER_TILE],
			const SizeT	&guarded_elements) {}
	};

	// Interface
	static __device__ __forceinline__ void Invoke(
		T *dest,
		T src[LOADS_PER_TILE],
		SizeT scatter_offsets[LOADS_PER_TILE],
		const SizeT	&guarded_elements)
	{
		Iterate<0, LOADS_PER_TILE>::Invoke(dest, src, scatter_offsets, guarded_elements);
	}
};



} // namespace util
} // namespace b40c

