/**
 * tcc -std=c99 xic.c -o xic
 *
 * Tool to compress/decompress FFXI server messages.
 *
 * I'm not sure what the algorithm is, but it seems to work on separate encoding and
 * decoding tables. (It seems to be some sort of cumulative substitution coder)
 *
 * At most encoding outputs 8 times bigger buffer than original for decoding.
 * However this buffer is mostly zeros and needs to be only expanded during decoding,
 * thus the actual information sent over wire is:
 * uint32_t (expanded buffer size) + (<expanded buffer size> + 7) / 8 bytes
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <assert.h>
#include <err.h>

#if (defined(__BYTE_ORDER__) && __BYTE_ORDER__ == __ORDER_BIG_ENDIAN__) || \
    (defined(__BYTE_ORDER) && __BYTE_ORDER == __BIG_ENDIAN) || \
    defined(__BIG_ENDIAN__) || \
    defined(__ARMEB__) || \
    defined(__THUMBEB__) || \
    defined(__AARCH64EB__) || \
    defined(_MIBSEB) || defined(__MIBSEB) || defined(__MIBSEB__)
#  define XIC_BIG_ENDIAN 1
#else
#  define XIC_BIG_ENDIAN 0
#endif

#if XIC_BIG_ENDIAN
#   if defined(__clang__) || (__GNUC__ >= 4 && __GNUC_MINOR__ >= 3 && !defined(__MINGW32__) && !defined(__MINGW64__))
#     define bswap16 __builtin_bswap16
#     define bswap32 __builtin_bswap32
#     define bswap64 __builtin_bswap64
#   elif defined(__GLIBC__)
#     include <byteswap.h>
#     define bswap16 __bswap_16
#     define bswap32 __bswap_32
#     define bswap64 __bswap_64
#   elif defined(__NetBSD__)
#     include <sys/types.h>
#     include <machine/bswap.h> /* already named bswap16/32/64 */
#   elif defined(_MSC_VER)
#     define bswap16 _byteswap_ushort
#     define bswap32 _byteswap_ulong
#     define bswap64 _byteswap_uint64
#   else
#     error "No compiler builtins for byteswap available"
#   endif
#endif

// Resolve the next address in jump table (0 == no jump, 1 == next address)
#define JMPBIT(table, i) ((table[i / 8] >> (i & 7)) & 1)

struct xic_table {
   uint32_t *data;
   size_t size;
};

struct xic_jump {
   const void *ptr;
};

struct xic {
   struct xic_table enc;
   struct xic_table dec;
   struct xic_jump *jump; // Always same size as dec table
};

static void
swap32_if_be(uint32_t *v, const size_t memb)
{
#if XIC_BIG_ENDIAN
   for (size_t i = 0; i < memb; ++i)
      v[i] = bswap32(v[i]);
#else
   (void)v, (void)memb;
#endif
}

static void
xic_table_release(struct xic_table *table)
{
   if (!table)
      return;

   free(table->data);
   *table = (struct xic_table){0};
}

static void
read_to_xic_table(const char *file, struct xic_table *table)
{
   assert(table);
   xic_table_release(table);

   if (!file)
      return;

   FILE *f;
   if (!(f = fopen(file, "rb")))
      err(EXIT_FAILURE, "fopen(%s, rb)", file);

   fseek(f, 0, SEEK_END);
   const size_t size = ftell(f);
   fseek(f, 0, SEEK_SET);

   table->size = size / sizeof(table->data[0]);
   if (!(table->data = calloc(table->size, sizeof(table->data[0]))))
      err(EXIT_FAILURE, "calloc");

   fread(table->data, sizeof(table->data[0]), table->size, f);
   fclose(f);

   swap32_if_be(table->data, table->size);
}

static void
populate_jump_table(struct xic_jump **jump, const struct xic_table *table)
{
   assert(jump && table);

   free(*jump);
   *jump = NULL;

   if (!table->data)
      return;

   if (!(*jump = calloc(table->size, sizeof(struct xic_jump))))
      err(EXIT_FAILURE, "calloc");

   // Base address of dec table, if we substract pointer in dec table, we should should be
   // able to normalize them to offsets starting from 0.
   const uint32_t base = table->data[0] - sizeof(base);

   for (size_t i = 0; i < table->size; ++i) {
      if (table->data[i] > 0xff) {
         // Everything over 0xff are pointers.
         // These pointers will be traversed until we hit data.
         (*jump)[i].ptr = *jump + (table->data[i] - base) / sizeof(base);
      } else {
         // Everything equal or less to 0xff is 8bit data.
         // The pointers at offsets -3 and -2 in table must be zero for each non-zero data entry
         // This approach assumes pointers are at least 8bit on the system.
         (*jump)[i].ptr = (void*)(uintptr_t)table->data[i];
         assert(!(*jump)[i].ptr || (!(*jump)[i-2].ptr && !(*jump)[i-3].ptr));
      }
   }
}

static inline size_t
xic_compressed_size(const size_t sz)
{
   return (sz + 7) / 8;
}

static void
xic_enc_sub(const uint8_t *b32, const size_t read, const size_t elem, uint8_t *out, const size_t out_sz)
{
   assert(b32 && out);

   if (xic_compressed_size(elem) > sizeof(uint32_t))
      errx(EXIT_FAILURE, "xic_enc_sub: element exceeds 4 bytes (%zu)", elem);

   if (xic_compressed_size(read + elem) > out_sz)
      errx(EXIT_FAILURE, "xic_enc_sub: ran out of space (%zu : %zu : %zu)", read, elem, out_sz);

   for (size_t i = 0; i < elem; ++i) {
      const uint8_t shift = (read + i) & 7;
      const size_t v = (read + i) / 8;
      const size_t inv_mask = ~(1 << shift);
      assert(shift < 8);
      out[v] = (inv_mask & out[v]) + (JMPBIT(b32, i) << shift);
   }
}

static size_t
xic_enc(struct xic *xic, const uint8_t *in, const size_t in_sz, uint8_t *out, const size_t out_sz)
{
   assert(xic && in && out);
   assert(xic->enc.data);

   size_t read = 0;
   const size_t max_sz = (out_sz - 1) * 8; // Output buffer may be at least 8 times big than original
   for (size_t i = 0; i < in_sz; ++i) {
      const size_t index = (int8_t)in[i] + 0x180;
      assert(index < xic->enc.size);
      const size_t elem = xic->enc.data[index];
      if (elem + read < max_sz) {
         const size_t index2 = (int8_t)in[i] + 0x80;
         assert(index2 < xic->enc.size);
         uint32_t v = xic->enc.data[index2];
         swap32_if_be(&v, 1);
         uint8_t b32[sizeof(v)];
         memcpy(b32, &v, sizeof(b32));
         xic_enc_sub(b32, read, elem, out + 1, out_sz - 1);
         read += elem;
      } else if (in_sz + 1 >= out_sz) {
         // Ran if input doesn't fit output, outputs garbage(?)
         warnx("xic_enc: ran out of space, outputting garbage(?) (%zu : %zu : %zu : %zu)", read, elem, max_sz, i);
         memset(out, 0, (out_sz / 4) + (in_sz & 3));
         memset(out + 1, in_sz, in_sz / 4);
         memset(out + 1 + in_sz / 4, (in_sz + 1) * 8, in_sz & 3);
         return in_sz;
      } else {
         errx(EXIT_FAILURE, "xic_enc: ran out of space (%zu : %zu : %zu : %zu)", read, elem, max_sz, i);
      }
   }

   out[0] = 1;
   return read + 8;
}

static size_t
xic_dec(struct xic *xic, const uint8_t *in, const size_t in_sz, uint8_t *out, const size_t out_sz)
{
   assert(xic && in && out);
   assert(xic->dec.data);

   const struct xic_jump *jmp = xic->jump[0].ptr;
   assert(jmp >= xic->jump && jmp <= xic->jump + xic->dec.size);

   if (in[0] != 1)
      errx(EXIT_FAILURE, "xic_dec: not a valid xic data");

   size_t w = 0;
   const uint8_t *data = in + 1;
   for (size_t i = 0; i < in_sz && w < out_sz; ++i) {
      jmp = jmp[JMPBIT(data, i)].ptr;
      assert(jmp >= xic->jump && jmp <= xic->jump + xic->dec.size);

      // Repeat until there is nowhere to jump to
      if (jmp[0].ptr != 0 || jmp[1].ptr != 0)
         continue;

      // The remaining address should be data
      assert(jmp[3].ptr <= (void*)0xff);
      out[w++] = (uint8_t)(uintptr_t)jmp[3].ptr;
      jmp = xic->jump[0].ptr;
   }

   return w;
}

static void
xic_init(struct xic *xic, const char *enc_file, const char *dec_file)
{
   assert(xic);
   *xic = (struct xic){0};
   read_to_xic_table(enc_file, &xic->enc);
   read_to_xic_table(dec_file, &xic->dec);
   populate_jump_table(&xic->jump, &xic->dec);
}

static void
xic_release(struct xic *xic)
{
   if (!xic)
      return;

   xic_table_release(&xic->enc);
   xic_table_release(&xic->dec);
   free(xic->jump);
   *xic = (struct xic){0};
}

struct buffer {
   uint8_t *data;
   size_t size;
};

static void
read_stdin_to_buffer(struct buffer *buffer)
{
   assert(buffer);
   free(buffer->data);

   size_t allocated;
   const size_t step = 4096;
   if (!(buffer->data = malloc((allocated = step))))
      err(EXIT_FAILURE, "malloc");

   size_t read;
   while ((read = fread(buffer->data + (allocated - step), 1, step, stdin)) == step)
      if (!(buffer->data = realloc(buffer->data, (allocated += step))))
         err(EXIT_FAILURE, "realloc");

   buffer->size = allocated - step + read;
}

static void
buffer_release(struct buffer *buffer)
{
   if (!buffer)
      return;

   free(buffer->data);
   *buffer = (struct buffer){0};
}

static void
write_buf_zero_rest(const uint8_t *buf, const size_t buf_sz, const size_t must_write, FILE *f)
{
   const size_t wrote = (must_write > buf_sz ? buf_sz : must_write);
   fwrite(buf, 1, wrote, f);

   for (size_t i = 0; i < must_write - wrote; ++i)
      fwrite((char[]){0}, 1, 1, f);
}

static void
usage(const char *basename)
{
   errx(EXIT_FAILURE, "%s: <enc|dec> <table>", basename);
}

int
main(int argc, const char *argv[])
{
   if (argc < 3)
      usage(argv[0]);

   enum {
      MODE_NONE,
      MODE_ENC,
      MODE_DEC
   } mode = (!strcmp(argv[1], "enc") ? MODE_ENC : !strcmp(argv[1], "dec") ? MODE_DEC : MODE_NONE);

   if (!mode)
      usage(argv[0]);

   struct xic xic;
   xic_init(&xic, (mode == MODE_ENC ? argv[2] : NULL), (mode == MODE_DEC ? argv[2] : NULL));

   struct buffer input = {0};
   read_stdin_to_buffer(&input);

   uint8_t *out;
   static size_t out_max_sz = 1750; // map_config.buffer_size
   if (!(out = calloc(out_max_sz, 1)))
      err(EXIT_FAILURE, "calloc");

   size_t out_sz, xic_sz;
   switch (mode) {
      case MODE_ENC:
         xic_sz = xic_enc(&xic, input.data, input.size, out, out_max_sz);
         out_sz = xic_compressed_size(xic_sz);
         warnx("input: %zu bytes output: %zu bytes (expanded: %zu bytes)", input.size, out_sz, xic_sz);
         break;
      case MODE_DEC:
         xic_sz = xic_dec(&xic, input.data, input.size, out, input.size);
         out_sz = xic_sz;
         warnx("input: %zu bytes (expanded: %zu bytes) output: %zu bytes", xic_compressed_size(input.size), input.size, xic_sz);
         break;
      default:
         err(EXIT_FAILURE, "unknown mode");
         break;
   }

   // What XI actually does is that it writes the xic_sz into packet, but only writes
   // (xic_sz + 7) / 8 from the buffer to the packet. So effectively this is where the
   // actual compression happens. The original xic_sz is needed for decompression.
   //
   // This tool however will only write the pre-filter output, meaning you can encode
   // input and decode the output, without mungling with the data.
   write_buf_zero_rest(out, out_sz, xic_sz, stdout);

   free(out);
   buffer_release(&input);
   xic_release(&xic);
   return EXIT_SUCCESS;
}