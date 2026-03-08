#ifndef AASDK_WRAPPER_H
#define AASDK_WRAPPER_H

#ifdef __cplusplus
extern "C" {
#endif

/* Opaque pointer to represent an AASDK context or main object */
typedef struct AASDK_Context AASDK_Context;

/* 
 * Create and initialize the AASDK context.
 * Returns a pointer to the context, or NULL on failure.
 */
AASDK_Context* aasdk_create_context(void);

/* 
 * Destroy the AASDK context and free resources.
 */
void aasdk_destroy_context(AASDK_Context* ctx);

/* 
 * Example function to start a connection or service.
 * Returns 0 on success, or a negative error code.
 */
int aasdk_start(AASDK_Context* ctx);

/* 
 * Example function to stop a connection or service.
 */
void aasdk_stop(AASDK_Context* ctx);

#ifdef __cplusplus
}
#endif

#endif /* AASDK_WRAPPER_H */